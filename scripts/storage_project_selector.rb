#! /usr/bin/env ruby
# frozen_string_literal: true

# vi: set ft=ruby :

# -*- mode: ruby -*-

# This script is a helper for selecting projects to replicate to other gitaly shard
# storage node systems.
#
# This script is intended to be invoked as user "$USER-rails" from a gitlab-rails
# console system.
#
# Staging example:
#
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_project_selector.rb --print-shards
#    gitlab-rails runner  /var/opt/gitlab/scripts/storage_project_selector.rb nfs-file-01 --staging --print-configured-gitaly-shards
#    gitlab-rails runner  /var/opt/gitlab/scripts/storage_project_selector.rb nfs-file-01 --staging --print-largest
#
# Production example:
#
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_project_selector.rb --print-shards
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_project_selector.rb nfs-file-35 --print-largest

require 'csv'
require 'json'
require 'date'
require 'logger'
require 'optparse'

begin
  require '/opt/gitlab/embedded/service/gitlab-rails/config/environment.rb'
rescue LoadError => e
  warn "WARNING: #{e.message}"
end

# Storage module
module Storage
  # ProjectSelectorScript module
  module ProjectSelectorScript
    LOG_TIMESTAMP_FORMAT = '%Y-%m-%d %H:%M:%S'
    DEFAULT_NODE_CONFIG = {}.freeze
  end

  def self.get_node_configuration
    return ::Gitlab.config.repositories.storages.dup if defined? ::Gitlab

    ::ProjectSelectorScript::DEFAULT_NODE_CONFIG
  end

  def self.node_configuration
    @node_configuration ||= get_node_configuration
  end

  class UserError < StandardError; end
end

# Re-open the Storage module to add the Config module
module Storage
  # ProjectSelectorScript module
  module ProjectSelectorScript
    # Config module
    module Config
      DEFAULTS = {
        log_level: Logger::INFO,
        api_endpoints: {
          staging: 'https://staging.gitlab.com/api/v4',
          production: 'https://gitlab.com/api/v4'
        },
        long_query_timeout: 600000,
        limit: 30,
        format: :json,
        clauses: {
          delete_error: nil,
          pending_delete: false,
          project_statistics: { commit_count: 1..Float::INFINITY },
          mirror: false
        },
        count: false,
        largest_only: false,
        configured_gitaly_shards: false,
        refresh_statistics: false,
        include_mirrors: false,
        stats: [:commit_count, :storage_size, :repository_size],
        group: nil,
        env: :production
      }.freeze
    end
  end
end

# Re-open the Storage module to add the Helpers module
module Storage
  # Helper methods
  module Helpers
    ISO8601_FRACTIONAL_SECONDS_LENGTH = 3

    def gitaly_address(shard)
      ::Storage.node_configuration.fetch(shard, {}).fetch('gitaly_address') do
        raise UserError, "Missing gitlab-rails configuration or entry: #{shard}"
      end
    end

    def timestamp
      DateTime.now.iso8601(ISO8601_FRACTIONAL_SECONDS_LENGTH)
    end

    def largest_denomination(bytes)
      if bytes.to_gb.positive?
        "#{bytes.to_gb} GB"
      elsif bytes.to_mb.positive?
        "#{bytes.to_mb} MB"
      elsif bytes.to_kb.positive?
        "#{bytes.to_kb} KB"
      else
        "#{bytes} Bytes"
      end
    end
  end
end

# Re-open the Storage module to add the Logging module
module Storage
  # This module defines logging methods
  module Logging
    def initialize_log
      STDOUT.sync = true
      timestamp_format = ::Storage::ProjectSelectorScript::LOG_TIMESTAMP_FORMAT
      log = Logger.new STDOUT
      log.level = Logger::INFO
      log.formatter = proc do |level, t, _name, msg|
        fields = { timestamp: t.strftime(timestamp_format), level: level, msg: msg }
        Kernel.format("%<timestamp>s %-5<level>s %<msg>s\n", **fields)
      end
      log
    end

    def log
      @log ||= initialize_log
    end

    def debug_command(cmd)
      log.debug "Command: #{cmd}"
      cmd
    end

    def log_error(err, message = nil, error = {})
      error[:error] = {
        timestamp: timestamp,
        message: message.nil? ? err.message : format(message, message: err.message)
      }
      error[:error][:backtrace] = err.backtrace unless err.is_a?(UserError)
      puts JSON.pretty_generate(error)
    end

    def log_info(info = {})
      info[:timestamp] = timestamp
      puts JSON.pretty_generate(info)
    end
  end
end

# Re-open the Storage module to add the CommandLineSupport module
module Storage
  # Support for command line arguments
  module CommandLineSupport
    # OptionsParser class
    class OptionsParser
      include ::Storage::Helpers
      attr_reader :parser, :options

      def initialize
        @parser = OptionParser.new
        @options = ::Storage::ProjectSelectorScript::Config::DEFAULTS.dup
        define_options
      end

      def define_options
        @parser.banner = "Usage: #{$PROGRAM_NAME} [options] <source_shard> <destination_shard>"
        @parser.separator ''
        @parser.separator 'Options:'
        define_head
        define_format_option
        define_refresh_stats_option
        define_count_option
        define_shards_list_option
        define_largest_option
        define_limit_option
        define_group_option
        define_include_mirrors_option
        define_env_option
        define_verbose_option
        define_tail
      end

      def define_head
        description = 'Name of the source gitaly storage shard server'
        @parser.on_head('<source_shard>', description) do |server|
          @options[:source_shard] = server
        end
        description = 'Name of the destination gitaly storage shard server'
        @parser.on_head('<destination_shard>', description) do |server|
          @options[:destination_shard] = server
        end
      end

      def define_format_option
        description = 'Output format (json or CSV); default: json'
        @parser.on('--format=<json|csv>', description) do |format_type|
          @options[:format] = format_type.downcase.to_sym
        end
      end

      def define_refresh_stats_option
        description = 'Refresh all project statistics; WARNING: ignores --dry-run'
        @parser.on('-r', '--refresh-stats', description) do
          @options[:refresh_statistics] = true
        end
      end

      def define_count_option
        @parser.on('-N', '--count', 'How many projects are on current file server') do
          @options[:count_only] = true
        end
      end

      def define_shards_list_option
        @parser.on('-S', '--shards-list', 'List all known repository storage shard nodes') do
          @options[:configured_gitaly_shards] = true
        end
      end

      def define_largest_option
        description = 'Find the single largest project repository on current file server'
        @parser.on('-L', '--largest', description) do
          @options[:largest_only] = true
        end
      end

      def define_limit_option
        description = "Maximum migrations; default: #{@options[:limit]}"
        @parser.on('-l', '--limit=<n>', Integer, description) do |limit|
          @options[:limit] = limit
        end
      end

      def define_group_option
        @parser.on('-g', '--group=<group_name>', String, 'Filter projects by group') do |group|
          @options[:group] = group
        end
      end

      def define_include_mirrors_option
        @parser.on('-M', '--include-mirrors', 'Include mirror repositories') do
          @options[:include_mirrors] = true
        end
      end

      def define_env_option
        @parser.on('--staging', 'Use the staging environment') do
          @options[:env] = :staging
        end
      end

      def define_verbose_option
        @parser.on('-v', '--verbose', 'Increase logging verbosity') do
          @options[:log_level] -= 1
        end
      end

      def define_tail
        @parser.on_tail('-?', '--help', 'Show this message') do
          puts @parser
          exit
        end
      end
    end
    # class OptionsParser

    def demand(options, arg, positional = false)
      return options[arg] unless options[arg].nil?

      required_arg = positional ? "<#{arg}>" : "--#{arg.to_s.gsub(/_/, '-')}"
      raise UserError, "Required argument: #{required_arg}"
    end

    def parse(args = ARGV, file_path = ARGF)
      opt = OptionsParser.new
      args.push('-?') if args.empty?
      opt.parser.parse!(args)
      opt.options[:source_shard] = args.shift
      opt.options[:destination_shard] = args.shift
      opt.options
    rescue OptionParser::InvalidArgument, OptionParser::InvalidOption,
           OptionParser::MissingArgument, OptionParser::NeedlessArgument => e
      puts e.message
      puts opt.parser
      exit
    rescue OptionParser::AmbiguousOption => e
      abort e.message
    end
  end
  # module CommandLineSupport
end
# module Storage

# Re-open the Storage module to define the Verifier class
module Storage
  # The ProjectSelector class
  class ProjectSelector
    include ::Storage::Helpers
    include ::Storage::Logging
    attr_reader :options
    def initialize(options)
      @options = options
      log.level = @options[:log_level]
    end

    def get_namespace(group)
      namespace_id = Namespace.find_by(path: group)
      raise UserError, 'No such namespace' if namespace_id.nil?

      namespace_id
    rescue StandardError => e
      log_error(e, "Error finding given group name '#{group}': %{message}")
      abort
    end

    def namespace_filter(clauses, group)
      return clauses if group.nil? || group.empty?

      clauses.merge(namespace_id: get_namespace(group))
    end

    def with_timeout(interval_in_seconds)
      ActiveRecord::Base.connection.execute "SET statement_timeout = #{interval_in_seconds}"
      yield
    end

    def print_count
      repository_storage = options[:source_shard]
      clauses = namespace_filter(options[:clauses].dup, options[:group])
      clauses.merge!(repository_storage: repository_storage)
      clauses.delete(:mirror) if options[:include_mirrors]
      query = Project.joins(:statistics).where(**clauses)
      count = Project.transaction do
        with_timeout(options[:long_query_timeout]) { query.size }
      end
      log_info(repository_storage: repository_storage, movable_project_count: count)
    rescue StandardError => e
      log_error(e, "Failed to count movable projects: %{message}")
      abort
    end

    def print_configured_gitaly_shards
      shards = ::Storage.node_configuration.sort.collect do |shard_name, config|
        { repository_storage: shard_name, gitaly_address: config['gitaly_address'] }
      end
      log_info({ shards: shards })
    end

    def project_details(project)
      {
        id: project.id,
        name: project.name,
        full_path: project.full_path,
        disk_path: project.disk_path,
        repository_storage: project.repository_storage,
        destination_repository_storage: options[:destination_shard],
        size: largest_denomination(project.statistics.repository_size),
        repository_size_bytes: project.statistics.repository_size
      }
    end

    def print_largest_project
      project = get_projects(limit: 1).first
      project = Project.find_by(id: project.id)
      raise 'No project with id: ' + project_id if project.nil?

      log_info(project_details(project))
    rescue StandardError => e
      log_error(e, "Failed to get largest project: %{message}")
      abort
    end

    def get_projects(parameters = {})
      opts = options.merge(parameters)
      clauses = namespace_filter(opts[:clauses].dup, opts[:group])
      clauses.merge!(repository_storage: opts[:source_shard])
      clauses.delete(:mirror) if opts[:include_mirrors]
      # Query all projects on the given repository storage shard, sort by
      # size descending, then sort by last activity date ascending in order
      # to select the most idle and largest projects first.
      query = Project.joins(:statistics)
      query = query.where(**clauses)
      query = query.order('project_statistics.repository_size DESC')
      query = query.order('last_activity_at ASC')
      query = query.limit(opts[:limit]) if opts[:limit].positive?
      Project.transaction do
        with_timeout(opts[:long_query_timeout]) do
          query.collect { |project| project_details(project) }
        end
      end
    rescue StandardError => e
      log_error(e, "Failed to get project identifiers: %{message}")
      abort
    end
  end
  # class ProjectSelector
end
# module Storage

# Re-open the registry module to add ProjectSelectorScript module
module Storage
  # ProjectSelectorScript module
  module ProjectSelectorScript
    include ::Storage::Helpers
    include ::Storage::Logging
    include ::Storage::CommandLineSupport

    def main(args = parse(ARGV, ARGF))
      unless args[:configured_gitaly_shards]
        source_shard = demand(args, :source_shard, true)
        destination_shard = demand(args, :destination_shard, true)
        gitaly_source_address = gitaly_address(source_shard)
        gitaly_destination_address = gitaly_address(destination_shard)
        raise UserError, 'Destination and source gitaly shard fqdn may not be the same' if gitaly_source_address == gitaly_destination_address
      end

      selector = ::Storage::ProjectSelector.new(args)
      if args[:configured_gitaly_shards]
        selector.print_configured_gitaly_shards
        exit
      end
      if args[:count_only]
        selector.print_count
        exit
      end
      if args[:largest_only]
        selector.print_largest_project
        exit
      end

      projects = selector.get_projects
      if args[:format] == :csv
        puts CSV.generate { |csv| projects.each { |project| csv << project.values } }
      else
        log_info(projects: projects)
      end
    rescue UserError => e
      log_error(e)
      abort
    rescue StandardError => e
      log_error(e)
      abort
    rescue SystemExit
      exit
    rescue Interrupt => e
      $stderr.write "\r\n#{e.class}\n"
      $stderr.flush
      $stdin.echo = true
      exit 0
    end
  end
  # ProjectSelectorScript module
end
# Storage module

# Anonymous object avoids namespace pollution
Object.new.extend(::Storage::ProjectSelectorScript).main if $PROGRAM_NAME == __FILE__

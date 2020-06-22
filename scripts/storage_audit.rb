#! /usr/bin/env ruby
# frozen_string_literal: true

# vi: set ft=ruby :

# -*- mode: ruby -*-

# This script must be ran on a gitaly shard node. It will find all
# hashed storage git repositories, and do a reverse lookup on their
# disk paths to check if the database confirms that their residence
# is valid on the given shard host.
#
# ssh file-01-stor-gstg.c.gitlab-staging-1.internal
# sudo mkdir -p /var/opt/gitlab/scripts/inventory.d /var/opt/gitlab/scripts/leftovers.d
# sudo chgrp git /var/opt/gitlab/scripts/inventory.d /var/opt/gitlab/scripts/leftovers.d
# sudo chmod 0775 /var/opt/gitlab/scripts/inventory.d /var/opt/gitlab/scripts/leftovers.d
#
# Staging execution:
#
# ssh file-01-stor-gstg.c.gitlab-staging-1.internal
# sudo gitlab-rails runner /var/opt/gitlab/scripts/storage_audit.rb --dry-run=yes
# sudo gitlab-rails runner /var/opt/gitlab/scripts/storage_audit.rb --dry-run=no
#
# Production execution:
#
# ssh file-01-stor-gprd.c.gitlab-production.internal
# sudo gitlab-rails runner /var/opt/gitlab/scripts/storage_audit.rb --dry-run=yes
# sudo gitlab-rails runner /var/opt/gitlab/scripts/storage_audit.rb --dry-run=no
#
# Example results:
#
# root@file-01-stor-gstg.c.gitlab-staging-1.internal:~# gitlab-rails runner /var/opt/gitlab/scripts/storage_audit.rb --dry-run=no
# 2020-06-22 03:16:56 INFO  Found 2337568 known git repositories on nfs-file01
# 2020-06-22 03:16:56 INFO  Auditing git repository projects
# 2020-06-22 03:21:55 INFO  2337568 of 2337568; 100.00%; found 697 repos on wrong shard

require 'fileutils'
require 'json'
require 'optparse'
require 'uri'

begin
  require '/opt/gitlab/embedded/service/gitlab-rails/config/environment.rb'
rescue LoadError => e
  warn "WARNING: #{e.message}"
end

# Storage module
module Storage
  # RepositoryAuditScript module
  module RepositoryAuditScript
    INVENTORY_TIMESTAMP_FORMAT = '%Y-%m-%d_%H%M%S'
    LOG_TIMESTAMP_FORMAT = '%Y-%m-%d %H:%M:%S'
    DEFAULT_NODE_CONFIG = {}.freeze
  end
  # module RepositoryAuditScript

  def self.get_node_configuration
    return ::Gitlab.config.repositories.storages.dup if defined? ::Gitlab

    ::RepositoryAuditScript::DEFAULT_NODE_CONFIG
  end

  def self.node_configuration
    @node_configuration ||= get_node_configuration
  end

  UserError = Class.new(StandardError)
end

# Re-open the Storage module to add the Config module
module Storage
  # RepositoryAuditScript module
  module RepositoryAuditScript
    # Config module
    module Config
      DEFAULTS = {
        dry_run: true,
        repositories_root_dir_path: '/var/opt/gitlab/git-data/repositories',
        hashed_storage_dir_name: '@hashed',
        inventory_dir_name: 'inventory.d',
        inventory_file_name: 'shard-git-repositories-%<date>s.txt',
        leftovers_dir_name: 'leftovers.d',
        leftovers_file_name: 'leftover-git-repositories-%<date>s.txt',
        inventory_find_command: 'find %<path>s -mindepth 2 -maxdepth 3 ' \
          '-type d -name "*.git" -not -name "*.wiki.git" -not -name "*.design.git" ' \
          '-not -name "*+moved+*.git" -not -name "*+deleted*.git"',
        reset: false,
        rescan: false,
        log_level: Logger::INFO,
        env: :production,
        status: '%<index>s of %<total>s; %<percent>.2f%%; found %<leftovers>s repos on wrong shard',
        gitaly_address_form: 'tcp://%<host>s:9999',
        project_keys: [:id, :disk_path, :repository_storage],
        slice_size: 20
      }.freeze
    end
  end
end

# Re-open the Storage module to add the Helpers module
module Storage
  # Helper methods
  module Helpers
    ISO8601_FRACTIONAL_SECONDS_LENGTH = 3

    def storage_gitaly_address(shard)
      ::Storage.node_configuration.fetch(shard, {}).fetch('gitaly_address') do
        raise UserError, "Missing gitlab-rails configuration or entry: #{shard}"
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
      timestamp_format = ::Storage::RepositoryAuditScript::LOG_TIMESTAMP_FORMAT
      log = Logger.new STDOUT
      log.level = Logger::INFO
      log.formatter = proc do |level, t, _name, msg|
        fields = { timestamp: t.strftime(timestamp_format), level: level, msg: msg }
        Kernel.format("%<timestamp>s %-5<level>s %<msg>s\n", **fields)
      end
      log
    end

    def initialize_progress_log
      log = initialize_log
      timestamp_format = ::Storage::RepositoryAuditScript::LOG_TIMESTAMP_FORMAT
      log.formatter = proc do |level, t, _name, msg|
        fields = { timestamp: t.strftime(timestamp_format), level: level, msg: msg }
        Kernel.format("\r%<timestamp>s %-5<level>s %<msg>s", **fields)
      end
      log
    end

    def log
      @log ||= initialize_log
    end

    def progress_log
      @progress_log ||= initialize_progress_log
    end

    def dry_run_notice
      log.info '[Dry-run] This is only a dry-run -- write operations will be logged but not executed'
    end

    def debug_command(cmd)
      log.debug "Command: #{cmd}"
      cmd
    end
  end
  # module Logging
end
# module Storage

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
        @options = ::Storage::RepositoryAuditScript::Config::DEFAULTS.dup
        define_options
      end

      def define_options
        @parser.banner = "Usage: #{$PROGRAM_NAME} [options]"
        @parser.separator ''
        @parser.separator 'Options:'
        define_head
        define_dry_run_option
        define_rescan_option
        define_forget_option
        define_env_option
        define_verbose_option
        define_tail
      end

      def define_head
        # Intentionally left empty
      end

      def define_dry_run_option
        description = 'Show what would have been done; default: yes'
        @parser.on('-d', '--dry-run=[yes/no]', description) do |dry_run|
          @options[:dry_run] = !dry_run.match?(/^(no|false)$/i)
        end
      end

      def define_rescan_option
        @parser.on('--rescan', 'Re-scan the repository storage inventory') do
          @options[:rescan] = true
        end
      end

      def define_forget_option
        @parser.on('--forget', 'Forget previously persisted repository storage inventory') do
          @options[:forget] = true
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

    def parse(args = ARGV, file_path = ARGF)
      opt = OptionsParser.new
      args.push('-?') if args.empty?
      opt.parser.parse!(args)
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

# Re-open the Storage module to define the RepositoryAuditor class
module Storage
  # The RepositoryAuditor class
  class RepositoryAuditor
    include ::Storage::Helpers
    include ::Storage::Logging
    attr_reader :options, :inventory_dir_path, :leftovers_file_path, :gitaly_address
    def initialize(options)
      @options = options
      log.level = @options[:log_level]
      @gitaly_address = format(
        options[:gitaly_address_form],
        host: `hostname --fqdn`.strip.split.first)
      init_paths
    end

    def init_paths
      leftovers_dir_path = File.join(__dir__, options[:leftovers_dir_name])
      FileUtils.mkdir_p(leftovers_dir_path) unless File.directory?(leftovers_dir_path)
      @leftovers_file_path = File.join(
        leftovers_dir_path, timestamped_file_name(options[:leftovers_file_name]))
      @inventory_dir_path = File.join(__dir__, options[:inventory_dir_name])
      FileUtils.mkdir_p(@inventory_dir_path) unless File.directory?(@inventory_dir_path)
    end

    def timestamped_file_name(file_name)
      format(
        file_name,
        date: Time.now.strftime(::Storage::RepositoryAuditScript::INVENTORY_TIMESTAMP_FORMAT))
    end

    def with_timeout(interval_in_seconds)
      ActiveRecord::Base.connection.execute "SET statement_timeout = #{interval_in_seconds}"
      yield
    end

    def persist(data)
      inventory_file_path = File.join(
        inventory_dir_path, timestamped_file_name(options[:inventory_file_name]))
      File.open(inventory_file_path, 'w') { |f| f.puts(data) }
      data
    end

    def scan_shard_repositories
      log.info "Scanning git repositories"
      repositories_root_dir_path = options[:repositories_root_dir_path]
      root_dir_pattern = %r{^#{repositories_root_dir_path}/}
      git_ext_pattern = %r{\.git$} # rubocop: disable Style/RegexpLiteral
      hashed_storage_root_path = File.join(options[:repositories_root_dir_path], options[:hashed_storage_dir_name])
      command = format(options[:inventory_find_command], path: hashed_storage_root_path)
      repositories = []
      if options[:dry_run]
        log.info "[Dry-run] Would have executed command: #{command}"
      else
        log.info "Executing command: #{command}"
        results = `#{command}`.strip.split
        results = results.map { |line| line.sub(root_dir_pattern, '').sub(git_ext_pattern, '') }
        repositories = persist(results)
      end
      repositories
    end

    def load_latest_inventory
      inventory_files = Dir.new(inventory_dir_path).children
      return if inventory_files.empty?

      latest_inventory_file_path = File.join(inventory_dir_path, inventory_files.max)
      return unless File.exist?(latest_inventory_file_path)

      IO.readlines(latest_inventory_file_path, chomp: true)
    end

    def latest_inventory
      if options[:rescan] || (inventory = load_latest_inventory).empty?
        inventory = scan_shard_repositories
      end
      log.info "Found #{inventory.length} known git repositories"
      inventory
    end

    def forget
      inventory_dir_children_paths = File.join(inventory_dir_path, '*')
      if options[:dry_run]
        log.info "[Dry-run] Would have executed command: rm -rf #{inventory_dir_children_paths}"
        return
      end
      log.info "Executing command: rm -rf #{inventory_dir_children_paths}"
      FileUtils.rm_rf(Dir.glob(inventory_dir_children_paths))
    end

    def update_status(iteration, leftovers_count, repository_count)
      progress_log.info(
        format(
          options[:status],
          index: iteration,
          total: repository_count,
          percent: ((iteration / repository_count.to_f) * 100).round(2),
          leftovers: leftovers_count))
    end

    def persist_leftovers(data)
      return if data.nil? || data.empty?

      File.open(leftovers_file_path, 'a') { |f| f.puts(data) }
    end

    def get_projects_by_disk_paths(disk_paths)
      keys = options[:project_keys]
      clauses = { project_repositories: { disk_path: disk_paths } }
      # This returns only values
      projects = Project.joins(:project_repository).where(**clauses).pluck(*keys)
      # The keys are also required, because this data will be serialized
      projects.map { |values_tuple| keys.zip(values_tuple).to_h }
    end

    def audit_repositories(inventory)
      return if inventory.empty?

      slice_size = options[:slice_size]
      repository_count = inventory.length
      leftovers_count = 0
      iteration = 0
      log.info "Auditing git repository projects"
      inventory.each_slice(slice_size) do |disk_paths|
        leftovers = get_projects_by_disk_paths(disk_paths).select do |project|
          storage_gitaly_address(project[:repository_storage]) != gitaly_address
        end
        leftovers_count += leftovers.length
        iteration += disk_paths.length
        update_status(iteration, leftovers_count, repository_count)
        persist_leftovers(leftovers.map(&:to_json))
      end
      puts "\n"
    end
  end
  # class RepositoryAuditor
end
# module Storage

# Re-open the Storage module to add RepositoryAuditScript module
module Storage
  # RepositoryAuditScript module
  module RepositoryAuditScript
    include ::Storage::Helpers
    include ::Storage::Logging
    include ::Storage::CommandLineSupport

    def main(args = parse(ARGV, ARGF))
      dry_run_notice if args[:dry_run]
      auditor = ::Storage::RepositoryAuditor.new(args)
      if args[:forget]
        auditor.forget
        exit
      end
      auditor.audit_repositories(auditor.latest_inventory)
    rescue UserError => e
      log.error(e)
      abort
    rescue StandardError => e
      log.error("Unexpected error: #{e}")
      e.backtrace.each { |t| log.error(t) }
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
  # RepositoryAuditScript module
end
# module Storage

# Anonymous object avoids namespace pollution
Object.new.extend(::Storage::RepositoryAuditScript).main if $PROGRAM_NAME == __FILE__

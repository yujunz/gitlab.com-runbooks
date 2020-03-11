#! /usr/bin/env ruby
# frozen_string_literal: true

# vi: set ft=ruby :

# -*- mode: ruby -*-

# Execution:
#
#    sudo su - root
#    mkdir -p /var/opt/gitlab/scripts
#    cd /var/opt/gitlab/scripts
#    curl --silent --remote-name https://gitlab.com/gitlab-com/runbooks/raw/master/scripts/storage_rebalance.rb
#    chmod +x storage_rebalance.rb
#    export PRIVATE_TOKEN=CHANGEME
#
# Staging example:
#
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --verbose --dry-run=yes --current-file-server=nfs-file01 --target-file-server=nfs-file09 --staging --count
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --verbose --dry-run=yes --current-file-server=nfs-file01 --target-file-server=nfs-file09 --staging --largest
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --verbose --dry-run=yes --current-file-server=nfs-file01 --target-file-server=nfs-file09 --staging --wait=10800 --max-failures=1 --validate-size --validate-checksum --refresh-stats
#
# Production examples:
#
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --verbose --dry-run=yes --current-file-server=nfs-file36 --target-file-server=nfs-file46 --wait=10800 --max-failures=1 --validate-size --validate-checksum --refresh-stats
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --verbose --dry-run=yes --current-file-server=nfs-file36 --target-file-server=nfs-file46 --count
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --verbose --dry-run=yes --current-file-server=nfs-file25 --target-file-server=nfs-file36
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --verbose --dry-run=yes --current-file-server=nfs-file34 --target-file-server=nfs-file42 --project=13007013 | tee /var/opt/gitlab/scripts/logs/nfs-file42.migration.$(date +%Y-%m-%d_%H%M).log
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --verbose --dry-run=yes --current-file-server=nfs-file34 --target-file-server=nfs-file42 | tee /var/opt/gitlab/scripts/logs/nfs-file42.migration.$(date +%Y-%m-%d_%H%M).log
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --verbose --dry-run=no --move-amount=10 --current-file-server=nfs-file27 --target-file-server=nfs-file38 --skip=9271929 | tee /var/opt/gitlab/scripts/logs/nfs-file38.migration.$(date +%Y-%m-%d_%H%M).log
#
# Verify the migration status of previously logged project migrations:
#
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --verify-only
#
# Logs may be reviewed:
#
#    export logd=/var/log/gitlab/storage_migrations; for f in `ls -t ${logd}`; do ls -la ${logd}/$f && cat ${logd}/$f; done
#

require 'csv'
require 'date'
require 'fileutils'
require 'json'
require 'io/console'
require 'logger'
require 'net/http'
require 'optparse'
require 'uri'

begin
  require '/opt/gitlab/embedded/service/gitlab-rails/config/environment.rb'
rescue LoadError => e
  warn "WARNING: #{e.message}"
end

# Storage module
module Storage
  # RebalanceScript module
  module RebalanceScript
    LOG_TIMESTAMP_FORMAT = '%Y-%m-%d %H:%M:%S'
    MIGRATION_TIMESTAMP_FORMAT = '%Y-%m-%d_%H%M%S'
    DEFAULT_NODE_CONFIG = {}.freeze
  end

  def self.get_node_configuration
    return ::Gitlab.config.repositories.storages.dup if defined? ::Gitlab

    ::RebalanceScript::DEFAULT_NODE_CONFIG
  end

  def self.node_configuration
    @node_configuration ||= get_node_configuration
  end

  class NoCommits < StandardError; end
  class MigrationTimeout < StandardError; end
  class CommitsMismatch < StandardError; end
  class ChecksumsMismatch < StandardError; end
  class RepositorySizesMismatch < StandardError; end
end

# Re-open the Storage module to add the Logging module
module Storage
  # This module defines logging methods
  module Logging
    def initialize_log
      STDOUT.sync = true
      timestamp_format = ::Storage::RebalanceScript::LOG_TIMESTAMP_FORMAT
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

    def dry_run_notice
      log.info '[Dry-run] This is only a dry-run -- write operations will be logged but not ' \
        'executed'
    end

    def debug_command(cmd)
      log.debug "Command: #{cmd}"
      cmd
    end

    def debug_lines(lines)
      return if lines.empty?

      log.debug do
        lines.each { |line| log.debug line unless line.nil? || line.empty? }
      end
    end
  end
end

# Re-open the Storage module to add the Config module
module Storage
  # RebalanceScript module
  module RebalanceScript
    # Config module
    module Config
      DEFAULTS = {
        dry_run: true,
        log_level: Logger::INFO,
        api_endpoints: {
          staging: 'https://staging.gitlab.com/api/v4/projects/%{project_id}/repository/commits',
          production: 'https://gitlab.com/api/v4/projects/%{project_id}/repository/commits'
        },
        move_amount: 0,
        repository_storage_update_timeout: 10800,
        long_query_timeout: 600000,
        max_failures: 3,
        clauses: {
          delete_error: nil,
          pending_delete: false,
          project_statistics: { commit_count: 1..Float::INFINITY },
          mirror: false
        },
        count: false,
        print_largest: false,
        verify_only: false,
        validate_checksum: false,
        validate_size: false,
        list_nodes: false,
        projects: [],
        excluded_projects: [],
        refresh_statistics: false,
        include_mirrors: false,
        stats: [:commit_count, :storage_size, :repository_size],
        group: nil,
        env: :production,
        logdir_path: '/var/log/gitlab/storage_migrations',
        migration_logfile_name: 'migrated_projects_%{date}.log'
      }.freeze
    end
  end
end

# Re-open the Storage module to add the Helpers module
module Storage
  # Helper methods
  module Helpers
    ISO8601_FRACTIONAL_SECONDS_LENGTH = 3

    def gitaly_address(storage_node_name)
      ::Storage.node_configuration.fetch(storage_node_name, {}).fetch('gitaly_address') do
        raise "Missing gitlab-rails configuration or entry: #{storage_node_name}"
      end
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
        @options = ::Storage::RebalanceScript::Config::DEFAULTS.dup
        define_options
      end

      def define_options
        @parser.banner = "Usage: #{$PROGRAM_NAME} [options] --current-file-server <servername> " \
          "--target-file-server <servername>"
        @parser.separator ''
        @parser.separator 'Options:'
        define_head
        define_dry_run_option
        define_projects_option
        define_csv_option
        define_skip_option
        define_refresh_stats_option
        define_count_option
        define_print_largest_option
        define_move_amount_option
        define_wait_option
        define_verify_only_option
        define_validate_checksum_option
        define_validate_size_option
        define_max_failures_option
        define_group_option
        define_include_mirrors_option
        define_env_option
        define_verbose_option
        define_tail
      end

      def define_head
        description = 'Source storage node server'
        @parser.on_head('--current-file-server=<SERVERNAME>', description) do |server|
          @options[:current_file_server] = server
        end
        description = 'Destination storage node server'
        @parser.on_head('--target-file-server=<SERVERNAME>', description) do |server|
          @options[:target_file_server] = server
        end
      end

      def define_dry_run_option
        description = 'Show what would have been done; default: yes'
        @parser.on('-d', '--dry-run=[yes/no]', description) do |dry_run|
          @options[:dry_run] = !dry_run.match?(/^(no|false)$/i)
        end
      end

      def define_projects_option
        description = 'Select specific projects to migrate'
        @parser.on('--projects=<project_id,...>', Array, description) do |project_identifiers|
          @options[:projects] ||= []
          unless project_identifiers.respond_to?(:all?) &&
              project_identifiers.all? { |s| resembles_integer? s }
            message = "Argument given for --projects must be a list of one or more integers"
            raise OptionParser::InvalidArgument, message
          end

          @options[:projects].concat project_identifiers.map(&:to_i).delete_if { |i| i <= 0 }
        end
      end

      def define_csv_option
        description = 'Absolute path to CSV file enumerating projects ids'
        @parser.on('--csv=<file_path>', description) do |file_path|
          unless File.exist? file_path
            message = "Argument given for --csv must be an absolute path to an existing file"
            raise OptionParser::InvalidArgument, message
          end

          @options[:projects] ||= []
          begin
            project_identifiers = IO.readlines(file_path, chomp: true)
            if project_identifiers.respond_to?(:all?) &&
                project_identifiers.all? { |s| resembles_integer? s }
              @options[:projects].concat project_identifiers.map(&:to_i).delete_if { |i| i <= 0 }
            else
              message = "Argument given for --csv must be an absolute path to a file containing " \
                "a list of one or more integers"
              raise OptionParser::InvalidArgument, message
            end
          rescue StandardError => e
            abort e.message
          end
        end
      end

      def define_skip_option
        description = 'Skip specific project(s)'
        @parser.on('--skip=<project_id,...>', Array, description) do |project_identifiers|
          @options[:excluded_projects] ||= []
          if project_identifiers.respond_to?(:all?) &&
              project_identifiers.all? { |s| resembles_integer? s }
            positive_numbers = project_identifiers.map(&:to_i).delete_if { |i| i <= 0 }
            @options[:excluded_projects].concat(positive_numbers)
          else
            message = 'Argument given for --skip must be a list of one or more integers'
            raise OptionParser::InvalidArgument, message
          end
        end
      end

      def define_refresh_stats_option
        description = 'Refresh all project statistics; WARNING: ignores --dry-run'
        @parser.on('-r', '--refresh-stats', description) do |refresh_statistics|
          @options[:refresh_statistics] = true
        end
      end

      def define_count_option
        @parser.on('-N', '--count', 'How many projects are on current file server') do |count|
          @options[:count] = true
        end
      end

      def define_print_largest_option
        description = 'Find the largest project repository on current file server'
        @parser.on('-L', '--print-largest', description) do |print_largest|
          @options[:print_largest] = true
        end
      end

      def define_move_amount_option
        description = "Gigabytes of repo data to move; default: #{@options[:move_amount]}, or " \
          'largest single repo if 0'
        @parser.on('-m', '--move-amount=<N>', Integer, description) do |move_amount|
          abort 'Size too large' if move_amount > 16_000
          # Convert given gigabytes to bytes
          @options[:move_amount] = (move_amount * 1024 * 1024 * 1024)
        end
      end

      def define_wait_option
        description = "Timeout in seconds for migration completion; default: " \
          "#{@options[:repository_storage_update_timeout]}"
        @parser.on('-w', '--wait=<N>', Integer, description) do |wait|
          @options[:repository_storage_update_timeout] = wait
        end
      end

      def define_verify_only_option
        description = 'Verify that projects have successfully migrated'
        @parser.on('-V', '--verify-only', description) do |verify_only|
          @options[:verify_only] = true
        end
      end

      def define_validate_checksum_option
        description = 'Validate project checksum is constant post-migration'
        @parser.on('-C', '--validate-checksum', description) do |checksum|
          @options[:validate_checksum] = true
        end
      end

      def define_validate_size_option
        description = 'Validate project repository size is constant post-migration'
        @parser.on('-S', '--validate-size', description) do |checksum|
          @options[:validate_size] = true
        end
      end

      def define_max_failures_option
        description = "Maximum failed migrations; default: #{@options[:max_failures]}"
        @parser.on('-f', '--max-failures=<N>', Integer, description) do |failures|
          @options[:max_failures] = failures
        end
      end

      def define_group_option
        @parser.on('--group=<GROUPNAME>', String, 'Filter projects by group') do |group|
          @options[:group] = group
        end
      end

      def define_include_mirrors_option
        @parser.on('-M', '--include-mirrors', 'Include mirror repositories') do |include_mirrors|
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

      def demand(arg)
        return unless @options[arg].nil?

        raise OptionParser::MissingArgument, 'Required arg: --' + arg.to_s.sub('_', '-')
      end

      def resembles_integer?(obj)
        obj.to_s.match?(/\A\d+\Z/)
      end
    end
    # class OptionsParser

    def password_prompt(prompt = 'Enter private API token: ')
      $stdout.write(prompt)
      $stdout.flush
      $stdin.noecho(&:gets).chomp
    ensure
      $stdin.echo = true
      $stdout.write "\r" + (' ' * prompt.length)
      $stdout.ioflush
    end

    def parse(args = ARGV, file_path = ARGF)
      opt = OptionsParser.new
      args.push('-?') if args.empty?
      opt.parser.parse!(opt.parser.order!(args) {})
      opt.demand(:current_file_server)
      opt.demand(:target_file_server)
      opt.options[:projects].concat CSV.new(file_path).to_a unless STDIN.tty? || STDIN.closed?
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

# Re-open the Storage module to define the Rebalancer class
module Storage
  # The Rebalancer class
  class Rebalancer
    include ::Storage::Logging
    include ::Storage::Helpers
    attr_reader :options
    def initialize(options)
      @options = options
      log.level = @options[:log_level]
    end

    def init_project_migration_logging
      fields = { date: Time.now.strftime(::Storage::RebalanceScript::MIGRATION_TIMESTAMP_FORMAT) }
      logfile_name = format(options[:migration_logfile_name], **fields)
      logdir_path = options[:logdir_path]
      FileUtils.mkdir_p logdir_path
      logfile_path = File.join(logdir_path, logfile_name)
      FileUtils.touch logfile_path
      logger = Logger.new(logfile_path, level: Logger::INFO)
      logger.formatter = proc { |level, t, name, msg| "#{msg}\n" }
      log.debug "Migration log file path: #{logfile_path}"
      logger
    rescue StandardError => e
      log.error "Failed to configure logging: #{e.message}"
      exit
    end

    def migration_log
      @migration_log ||= init_project_migration_logging
    end

    def migration_errors
      @errors ||= []
    end

    def get_commit_id(project_id)
      endpoints = options[:api_endpoints]
      environment = options[:env]
      url = endpoints.include?(environment) ? endpoints[environment] : endpoints[:production]
      abort "No api endpoint url is configured" if url.nil? || url.empty?
      url = format(url, project_id: project_id)
      uri = URI(url)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.request_uri)
      request['Private-Token'] = options.fetch(:private_token) do
        abort "A private API token is required."
      end

      log.debug "[The following curl command is for external diagnostic purposes only:]"
      log.debug "curl --verbose --silent '#{url}' --header \"Private-Token: ${PRIVATE_TOKEN}\""
      response = http.request(request)

      payload = JSON.parse(response.body)
      log.debug "Response code: #{response.code}"
      log.debug "Response payload sample: #{JSON.pretty_generate(payload.first)}"
      log.debug "Total commits: #{payload.length}"

      commit_id = nil
      if response.code.to_i == 200 && !payload.empty?
        first_commit = payload.first
        commit_id = first_commit['id']
      elsif payload.include? 'message'
        log.error "Error: #{payload['message']}"
      end

      commit_id
    end

    def wait_for_repository_storage_update(project)
      start = Time.now.to_i
      i = 0
      timeout = options[:repository_storage_update_timeout]
      while project.repository_read_only?
        sleep 1
        project.reload
        print '.'
        i += 1
        print "\n" if (i % 80).zero?
        elapsed = Time.now.to_i - start
        next unless elapsed >= timeout

        print "\n"
        log.warn ""
        log.warn "Timed out up waiting for project id: #{project.id} to move: #{elapsed} seconds"
        break
      end
      print "\n"
      if project.repository_storage == options[:target_file_server]
        log.info "Success moving project id:#{project.id}"
      else
        log.warn "Project id: #{project.id} still reporting incorrect file server"
      end
    end

    # rubocop: disable Metrics/AbcSize
    def migrate(project)
      log.info('=' * 72)
      log.info "Migrating project id: #{project.id}"
      log.info "  Size: ~#{largest_denomination(project.statistics.repository_size)}"
      log.debug "  Name: #{project.name}"
      log.debug "  Group: #{project.group.name}" unless project.group.nil?
      log.debug "  Storage: #{project.repository_storage}"
      log.debug "  Path: #{project.disk_path}"
      if options[:refresh_statistics]
        log.debug "Pre-refresh statistics:"
        options[:stats].each do |stat|
          log.debug "  #{stat.capitalize}: #{project.statistics[stat]}"
        end
        project.statistics.refresh!(only: options[:stats])
        log.debug "Post-refresh statistics:"
      else
        log.debug "Project statistics:"
      end
      options[:stats].each do |stat|
        log.debug "  #{stat}: #{project.statistics[stat]}"
      end

      original_commit_id = get_commit_id(project.id)
      if original_commit_id.nil?
        raise NoCommits, "Could not obtain any commits for project id " \
          "#{project.id}"
      end

      project.repository.expire_exists_cache
      original_checksum = project.repository.checksum if options[:validate_checksum]
      original_repository_size = project.statistics[:repository_size] if options[:validate_size]

      log_artifact = {
        id: project.id,
        path: project.disk_path,
        source: URI.parse(gitaly_address(project.repository_storage)).host,
        destination: URI.parse(gitaly_address(options[:target_file_server])).host
      }

      if options[:dry_run]
        log.info "[Dry-run] Would have moved project id: #{project.id}"
        migration_log.info log_artifact.merge({ dry_run: true }).to_json
        return
      end

      log.info "Scheduling migration for project id: #{project.id} to " \
        "#{options[:target_file_server]}"
      project.change_repository_storage(options[:target_file_server])
      project.save

      wait_for_repository_storage_update(project)
      post_migration_project = Project.find_by(id: project.id)

      if post_migration_project.repository_storage != options[:target_file_server]
        raise MigrationTimeout, "Timed out waiting for migration of " \
          "project id: #{post_migration_project.id}"
      end

      log.debug "Refreshing all statistics for project id: #{post_migration_project.id}"
      post_migration_project.statistics.refresh!

      log.info "Validating project integrity by comparing latest commit " \
        "identifiers before and after"
      current_commit_id = get_commit_id(post_migration_project.id)
      log.debug "Original commit id: #{original_commit_id}, current commit id: " \
        "#{current_commit_id}"
      if original_commit_id != current_commit_id
        raise CommitsMismatch, "Current commit id #{current_commit_id} " \
          "does not match original commit id #{original_commit_id}"
      end

      if options[:validate_checksum]
        log.info "Validating project integrity by comparing checksums " \
          "before and after"
        post_migration_project.repository.expire_exists_cache
        current_checksum = post_migration_project.repository.checksum
        log.debug "Original checksum: #{original_checksum}, current checksum: " \
          "#{current_checksum}"
        if original_checksum != current_checksum
          raise ChecksumsMismatch, "Current checksum #{current_checksum} " \
            "does not match original checksum #{original_checksum}"
        end
      end

      if options[:validate_size]
        log.info "Validating project integrity by comparing repository size " \
          "before and after"
        current_repository_size = post_migration_project.statistics[:repository_size]
        log.debug "Original repository size: #{original_repository_size}, current size: " \
          "#{current_repository_size}"
        if original_repository_size != current_repository_size
          raise RepositorySizesMismatch, "Current repository size #{current_repository_size} " \
            "does not match original repository size #{original_repository_size}"
        end
      end

      log.info "Migrated project id: #{post_migration_project.id}"
      log.debug "  Name: #{post_migration_project.name}"
      log.debug "  Storage: #{post_migration_project.repository_storage}"
      log.debug "  Path: #{post_migration_project.disk_path}"
      log_artifact[:date] = DateTime.now.iso8601(ISO8601_FRACTIONAL_SECONDS_LENGTH)
      migration_log.info log_artifact.to_json
    end
    # rubocop: enable Metrics/AbcSize

    def get_namespace(group)
      namespace_id = Namespace.find_by(path: group)
      raise "No such namespace" if namespace_id.nil?

      namespace_id
    rescue StandardError => e
      log.fatal "Error finding given group name '#{group}': #{e.message}"
      abort
    end

    def namespace_filter(clauses, group)
      return clauses if group.nil? || group.empty?

      log.info "Filtering projects by group: #{group}"
      clauses.merge(namespace_id: get_namespace(group))
    end

    def with_timeout(interval_in_seconds)
      ActiveRecord::Base.connection.execute "SET statement_timeout = #{interval_in_seconds}"
      yield
    end

    def print_count
      source_storage_node = options[:current_file_server]
      clauses = namespace_filter(options[:clauses].dup, options[:group])
      clauses.merge!(repository_storage: source_storage_node)
      clauses.delete(:mirror) if options[:include_mirrors]
      query = Project.joins(:statistics).where(**clauses)
      count = Project.transaction do
        with_timeout(options[:long_query_timeout]) { query.size }
      end
      log.info "Movable projects stored on #{source_storage_node}: #{count}"
    rescue StandardError => e
      log.fatal "Failed to count movable projects: #{e.message}"
      abort
    end

    def print_node_list
      ::Storage.node_configuration.sort.each do |repository_storage_node, node_config|
        gitaly_address = node_config['gitaly_address']
        log.info "#{repository_storage_node}: #{gitaly_address}"
      end
    end

    def print_largest_project
      project_id = get_project_ids(limit: 1).first
      project = Project.find_by(id: project_id)
      log.info "Largest project on #{options[:current_file_server]}: #{project_id}"
      log.info "  Name: #{project.name}"
      log.info "  Size: ~#{largest_denomination(project.statistics.repository_size)}"
    rescue StandardError => e
      log.fatal "Failed to get largest project: #{e.message}"
      abort
    end

    def get_project_ids(opts = {})
      default_opts = { projects: [], limit: -1 }
      opts = default_opts.merge(opts)
      given_project_identifiers = opts[:projects]
      excluded_projects = options[:excluded_projects]
      clauses = namespace_filter(options[:clauses].dup, options[:group])
      clauses.merge!(repository_storage: options[:current_file_server])
      unless given_project_identifiers.empty?
        # The user specified one or more project identifiers;
        # So don't filter out mirrors
        clauses.delete(:mirror)
        clauses.merge!(id: given_project_identifiers)
      end
      clauses.delete(:mirror) if options[:include_mirrors]
      # Query all projects on the current file server that have not failed
      # any previous delete operations, sort by size descending,
      # then sort by last activity date ascending in order to select the
      # most idle and largest projects first.
      query = Project.joins(:statistics)
      query = query.where(**clauses)
      unless excluded_projects.empty?
        log.debug "Excluding projects: #{excluded_projects}"
        query = query.where.not(id: excluded_projects)
      end
      query = query.order('project_statistics.repository_size DESC')
      query = query.order('last_activity_at ASC')
      query = query.limit(opts[:limit]) if opts[:limit].positive?
      Project.transaction do
        with_timeout(options[:long_query_timeout]) { query.pluck(:id) }
      end
    end

    # rubocop: disable Metrics/AbcSize
    def move_projects(project_ids, min_amount = options[:move_amount])
      log.info "Moving #{project_ids.length} projects"
      log.info "From: #{options[:current_file_server]}"
      log.info "To:   #{options[:target_file_server]}"
      log.debug "Project migration validation timeout: " \
        "#{options[:repository_storage_update_timeout]} seconds"

      total = 0
      project_ids.each do |project_id|
        begin
          project = Project.find_by(id: project_id)
          migrate(project)
          total += project.statistics.repository_size
        rescue NoCommits => e
          migration_errors << { project_id: project_id, message: e.message }
          log.error "Error: #{e}"
          log.warn "Skipping migration"
        rescue CommitsMismatch => e
          migration_errors << { project_id: project_id, message: e.message }
          log.error "Failed to validate integrity of project id: #{project_id}"
          log.error "Error: #{e}"
          log.warn "Skipping migration"
        rescue ChecksumsMismatch => e
          migration_errors << { project_id: project_id, message: e.message }
          log.error "Failed to validate integrity of project id: #{project_id}"
          log.error "Error: #{e}"
          log.warn "Skipping migration"
        rescue RepositorySizesMismatch => e
          migration_errors << { project_id: project_id, message: e.message }
          log.error "Failed to validate integrity of project id: #{project_id}"
          log.error "Error: #{e}"
          log.warn "Skipping migration"
        rescue MigrationTimeout => e
          migration_errors << { project_id: project_id, message: e.message }
          log.error "Timed out migrating project id: #{project_id}"
          log.error "Error: #{e}"
          log.warn "Skipping migration"
        rescue StandardError => e
          migration_errors << { project_id: project_id, message: e.message }
          log.error "Unexpected error migrating project id #{project_id}: #{e}"
          e.backtrace.each { |t| log.error t }
          log.warn "Skipping migration"
        end
        if migration_errors.length >= options[:max_failures]
          log.error "Failed too many times"
          break
        end
        break if min_amount.positive? && total > min_amount
      end
      total = largest_denomination(total)
      if options[:dry_run]
        log.info "[Dry-run] Would have processed #{total} of data"
      else
        log.info "Processed #{total} of data"
      end
    end
    # rubocop: enable Metrics/AbcSize

    def rebalance
      project_identifiers = options[:projects]
      move_amount_bytes = options[:move_amount]
      if !project_identifiers.empty?
        project_identifiers = get_project_ids(projects: project_identifiers)
        abort 'No valid project identifiers were given' if project_identifiers.empty?
      elsif move_amount_bytes.zero?
        log.info 'Option --move-amount not specified, will only move 1 project...'
        project_identifiers = get_project_ids(limit: 1)
      else
        log.info "Will move at least #{move_amount_bytes.to_gb} GB worth of data"
        project_identifiers = get_project_ids
      end

      move_projects(project_identifiers)

      log.info('=' * 72)
      log.info "Finished migrating projects from #{options[:current_file_server]} to " \
        "#{options[:target_file_server]}"
      unless migration_errors.empty?
        log.error "Encountered #{migration_errors.length} errors:"
        log.error JSON.pretty_generate(migration_errors)
        return 1
      end

      log.info "No errors encountered during migration"
    end
  end
  # class Rebalancer
end
# module Storage

# Re-open the Storage module to define the Verifier class
module Storage
  # The Verifier class
  class Verifier
    include ::Storage::Logging
    include ::Storage::Helpers
    def initialize(options)
      @options = options
      log.level = @options[:log_level]
    end

    def get_migrated_project_logs(log_file_paths)
      moved_projects_log_entries = []

      log_file_paths.each do |path|
        log.debug "Extracting project migration logs from: #{path}"
        File.readlines(path).each do |line|
          line.chomp!
          log.debug "Migration log entry: #{line}"
          moved_project = JSON.parse(line, symbolize_names: true)
          moved_projects_log_entries << moved_project unless moved_project[:dry_run]
        end
      end

      moved_projects_log_entries
    end

    def verify
      logdir_path = options[:logdir_path]
      logfile_name = format(options[:migration_logfile_name], date: '*')
      log_file_paths = Dir[File.join(logdir_path, logfile_name)].sort

      moved_projects = get_migrated_project_logs(log_file_paths)

      project_identifiers = moved_projects.map { |project| project[:id] }
      Project.find(project_identifiers).each do |project|
        if project.repository_read_only?
          log.info "The repository for project id #{project.id} is still marked read-only on " \
            "storage node #{project.repository_storage}"
        else
          log.info "The repository for project id #{project.id} appears to have successfully " \
            "migrated to #{project.repository_storage}"
        end
      end
      log.info "All logged project repository migrations are accounted for"
    end
  end
  # class Verifier
end
# module Storage

# Re-open the registry module to add RebalanceScript module
module Storage
  # RebalanceScript module
  module RebalanceScript
    include ::Storage::Logging
    include ::Storage::Helpers
    include ::Storage::CommandLineSupport

    def main(args = parse(ARGV, ARGF))
      dry_run_notice if args[:dry_run]

      source_storage_node = args[:current_file_server]
      destination_storage_node = args[:target_file_server]
      gitaly_source_address = gitaly_address(source_storage_node)
      gitaly_destination_address = gitaly_address(destination_storage_node)
      if gitaly_source_address == gitaly_destination_address
        raise 'Given destination git storage node must not have the same gitaly address as ' \
          'the source'
      end

      if args[:verify_only]
        ::Storage::Verifier.new(args).verify
        exit
      end

      rebalancer = ::Storage::Rebalancer.new(args)
      if args[:list_nodes]
        rebalancer.print_node_list
        exit
      end
      if args[:count]
        rebalancer.print_count
        exit
      end
      if args[:print_largest]
        rebalancer.print_largest_project
        exit
      end

      private_token = ENV.fetch('PRIVATE_TOKEN', nil)
      if private_token.nil? || private_token.empty?
        log.warn "No PRIVATE_TOKEN variable set in environment"
        private_token = password_prompt
        abort "Cannot proceed without a private API token." if private_token.empty?
      end

      rebalancer.options.store(:private_token, private_token)
      rebalancer.rebalance
    rescue StandardError => e
      log.fatal e.message
      e.backtrace.each { |trace| log.error trace }
      abort
    rescue SystemExit
      exit
    rescue Interrupt => e
      $stdout.write "\r\n#{e.class}\n"
      $stdout.flush
      $stdin.echo = true
      exit 0
    end
  end
  # RebalanceScript module
end
# Storage module

# Anonymous object avoids namespace pollution
Object.new.extend(::Storage::RebalanceScript).main if $PROGRAM_NAME == __FILE__

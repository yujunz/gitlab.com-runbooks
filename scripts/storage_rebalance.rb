#! /usr/bin/env ruby
# frozen_string_literal: true

# vi: set ft=ruby :

# -*- mode: ruby -*-

# A little local setup:
#
#    export GITLAB_GSTG_ADMIN_API_PRIVATE_TOKEN=CHANGEME
#    export GITLAB_GPRD_ADMIN_API_PRIVATE_TOKEN=CHANGEME
#    mkdir -p scripts/logs scripts/storage_migrations
#
# Staging example:
#
#    bundle exec scripts/storage_rebalance.rb nfs-file01 nfs-file09 --staging --max-failures=1 --verbose --dry-run=yes
#
# Production examples:
#
#    bundle exec scripts/storage_rebalance.rb nfs-file35 nfs-file50 --verbose --dry-run=yes --wait=10800 --max-failures=1
#    bundle exec scripts/storage_rebalance.rb nfs-file35 nfs-file50 --verbose --dry-run=yes --count
#    bundle exec scripts/storage_rebalance.rb nfs-file35 nfs-file50 --verbose --dry-run=yes
#    bundle exec scripts/storage_rebalance.rb nfs-file35 nfs-file50 --verbose --dry-run=yes --projects=13007013 | tee scripts/logs/nfs-file35.migration.$(date +%Y-%m-%d_%H%M).log
#    bundle exec scripts/storage_rebalance.rb nfs-file35 nfs-file50 --verbose --dry-run=yes | tee scripts/logs/nfs-file35.migration.$(date +%Y-%m-%d_%H%M).log
#    bundle exec scripts/storage_rebalance.rb nfs-file35 nfs-file50 --verbose --dry-run=no --move-amount=10 --skip=9271929 | tee scripts/logs/nfs-file35.migration.$(date +%Y-%m-%d_%H%M).log
#    bundle exec scripts/storage_rebalance.rb nfs-file53 nfs-file02 --wait=10800 --max-failures=1 --projects=19438807 --dry-run=yes | tee scripts/logs/nfs-file53.migration.$(date +%Y-%m-%d_%H%M).log
#    bundle exec scripts/storage_rebalance.rb nfs-file25 nfs-file07 --move-amount=300 --wait=10800 --max-failures=10 --dry-run=yes | tee scripts/logs/nfs-file25.migration.$(date +%Y-%m-%d_%H%M).log
#    bundle exec scripts/storage_rebalance.rb nfs-file47 nfs-file07 --move-amount=300 --wait=10800 --max-failures=4 --dry-run=yes | tee scripts/logs/nfs-file47.migration.$(date +%Y-%m-%d_%H%M).log
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
require 'ostruct'
require 'uri'

# Storage module
module Storage
  # RebalanceScript module
  module RebalanceScript
    LOG_TIMESTAMP_FORMAT = '%Y-%m-%d %H:%M:%S'
    MIGRATION_TIMESTAMP_FORMAT = '%Y-%m-%d_%H%M%S'
    LOG_META_INFO_LENGTH = 26
    DISPLAY_WIDTH = 80 - LOG_META_INFO_LENGTH
    DEFAULT_NODE_CONFIG = {}.freeze
    PROJECT_FIELDS = %i[
      id name full_path disk_path repository_storage destination_repository_storage
      size repository_size_bytes
    ].freeze
    INTEGER_PATTERN = /\A\d+\Z/.freeze
    SEPARATOR = ('=' * DISPLAY_WIDTH).freeze
    PROGRESS_BRAILLES = [
      "\u28F7", "\u28EF", "\u28DF", "\u287F", "\u28BF", "\u28FB", "\u28FD", "\u28FE"
    ].freeze
    PROGRESS_FULL_BRAILLE = "\u28FF"
    SECONDS_PER_SPIN = 5
    DEFAULT_TIMEOUT = 60 * 5

    # Config module
    module Config
      DEFAULTS = {
        dry_run: true,
        log_level: Logger::INFO,
        env: :production,
        token_env_variable_names: {
          staging: 'GITLAB_GSTG_ADMIN_API_PRIVATE_TOKEN',
          production: 'GITLAB_GPRD_ADMIN_API_PRIVATE_TOKEN'
        },
        password_prompt: 'Enter Gitlab admin API private token: ',
        console_nodes: {
          staging: 'console-01-sv-gstg.c.gitlab-staging-1.internal',
          production: 'console-01-sv-gprd.c.gitlab-production.internal'
        },
        api_endpoints: {
          staging: 'https://staging.gitlab.com/api/v4',
          production: 'https://gitlab.com/api/v4'
        },
        projects_api_uri: 'projects',
        projects_per_page: 100,
        projects_repository_api_uri: 'projects/%<project_id>s/repository',
        projects_by_id_api_uri: 'projects/%<project_id>s',
        projects_repository_storage_move_api_uri: 'projects/%<project_id>s/' \
          'repository_storage_moves/%<repository_storage_move_id>s',
        projects_repository_storage_moves_api_uri: 'projects/%<project_id>s/repository_storage_moves',
        projects_statistics_api_uri: 'projects/%<project_id>s/statistics',
        project_repository_move_states: {
          # For reference to the API state enumeration only:
          # initial: 1,
          # scheduled: 2,
          # started: 3,
          # finished: 4,
          # failed: 5,
          success: :finished,
          failure: :failed,
          in_progress: %i[initial scheduled started]
        },
        project_selector_script_path: '/var/opt/gitlab/scripts/storage_project_selector.rb',
        project_selector_command: 'sudo gitlab-rails runner ' \
          '%<project_selector_script_path>s ' \
          '%<source_shard>s %<destination_shard>s',
        ssh_command: 'ssh %<hostname>s -- %<command>s',
        move_amount: 0,
        repository_storage_update_timeout: 10800,
        max_failures: 3,
        retry_known_failures: false,
        limit: -1,
        use_tty_display_settings: false,
        projects: [],
        excluded_projects: [],
        logdir_path: File.expand_path(File.join(__dir__, 'storage_migrations')),
        migration_logfile_name: 'migrated_projects_%{date}.log',
        migration_error_logfile_prefix: 'failed_projects_',
        migration_error_logfile_name: 'failed_projects_%{date}.log',
        log_format: "%<timestamp>s %-5<level>s %<msg>s\n",
        log_format_progress: "\r%<timestamp>s %-5<level>s %<msg>s"
      }.freeze
    end
  end

  class UserError < StandardError; end
  class Timeout < StandardError; end
  class NoCommits < StandardError; end
  class MigrationTimeout < StandardError; end
  class ServiceFailure < StandardError
    attr_reader :repository_move
    def initialize(message, migration_state_info = nil)
      super(message)
      @repository_move = migration_state_info
    end
  end
  class CommitsMismatch < StandardError; end
  class ShardMismatch < StandardError; end
end

# Re-open the Storage module to add the Logging module
module Storage
  # This module defines logging methods
  module Logging
    LOG_FORMAT = "%<timestamp>s %-5<level>s %<msg>s\n"
    PROGRESS_LOG_FORMAT = "\r%<timestamp>s %-5<level>s %<msg>s"
    DEFAULT_LOG_ERROR_OPTIONS = {
      include_backtrace: false,
      persist: true
    }.freeze

    def formatter_procedure(format_template = LOG_FORMAT)
      proc do |level, t, _name, msg|
        format(
          format_template,
          timestamp: t.strftime(::Storage::RebalanceScript::LOG_TIMESTAMP_FORMAT),
          level: level, msg: msg)
      end
    end

    def initialize_log(formatter = formatter_procedure)
      STDOUT.sync = true
      log = Logger.new(STDOUT)
      log.level = Logger::INFO
      log.formatter = formatter
      log
    end

    def log
      @log ||= initialize_log
    end

    def progress_log
      @progress_log ||= initialize_log(formatter_procedure(::Storage::Logging::PROGRESS_LOG_FORMAT))
    end

    def with_log_level(log_level = Logger::INFO, &block)
      sv_log_level = log.level
      log.level = log_level
      block.call
    ensure
      log.level = sv_log_level
    end

    def log_separator
      log.info(::Storage::RebalanceScript::SEPARATOR)
    end

    def dry_run_notice
      log.info '[Dry-run] This is only a dry-run -- write operations will be logged but not ' \
        'executed'
    end

    def debug_command(cmd)
      log.debug "Command: #{cmd}"
      cmd
    end

    def log_and_record_migration_error(error, project, options = {})
      options = DEFAULT_LOG_ERROR_OPTIONS.merge(options)
      if error.respond_to?(:response)
        error_body = JSON.parse(error.response.body)
        symbolize_keys_deep!(error_body)
        error_message = error_body.fetch(:message, nil)
      end
      error_message ||= error.message if error.respond_to?(:message)
      error_record = { project_id: project[:id], message: error_message }
      error_record[:disk_path] = project[:disk_path] if project.include?(:disk_path)
      log_migration_error(project, error_record) if options[:persist]
      migration_errors << error_record
      if options[:include_backtrace]
        error.backtrace.each { |t| log.error t }
      else
        log.error "Error: #{error}"
      end
      log.warn "Skipping migration"
    end

    PRIVATE_TOKEN_HEADER_PATTERN = /Private-Token/i.freeze

    def get_request_headers(request)
      request.instance_variable_get('@header'.to_sym) || []
    end

    # rubocop: disable Style/PercentLiteralDelimiters
    # rubocop: disable Style/RegexpLiteral
    def to_unescaped_json(data)
      return data unless data.respond_to?(:to_json)

      data.to_json.gsub(%r[\\"], '"').gsub(%r[^"{], '{').gsub(%r[}"$], '}')
    end
    # rubocop: enable Style/PercentLiteralDelimiters
    # rubocop: enable Style/RegexpLiteral

    # This method reproduces a Net:HTTP request as a verbatim
    # port to a curl command, executable on the command line,
    # in order to make a given web-request portable.
    def debug_request(request)
      env_variable_name = options[:token_env_variable_names][options[:env]]
      headers = get_request_headers(request)
      log.debug "[The following curl command is for external diagnostic purposes only:]"
      curl_command = "curl --verbose --silent --compressed ".dup
      curl_command = curl_command.concat("--request #{request.method.to_s.upcase} ") if request.method != :get
      curl_command = curl_command.concat("'#{request.uri}'")
      header_arguments = headers.collect do |field, values|
        if PRIVATE_TOKEN_HEADER_PATTERN.match?(field)
          "--header \"#{field}: ${#{env_variable_name}}\""
        else
          "--header \"#{field}: #{values.join(',')}\""
        end
      end
      unless header_arguments.empty?
        curl_command = curl_command.concat(' ')
        curl_command = curl_command.concat(header_arguments.join(' '))
      end
      body = request.body
      curl_command = curl_command.concat(" --data '#{to_unescaped_json(body)}'") unless body.nil? || body.empty?
      log.debug curl_command
    end

    def debug_lines(lines)
      return if lines.empty?

      log.debug do
        lines.each { |line| log.debug line unless line.nil? || line.empty? }
      end
    end

    def load_migration_failures
      logfiles_glob = File.join(options[:logdir_path], format('%s*.log', options[:migration_error_logfile_prefix]))
      migration_failures = []
      Dir.glob(logfiles_glob).each do |file_path|
        IO.foreach(file_path) do |line|
          migration_failures << JSON.parse(line).transform_keys!(&:to_sym)
        end
      end
      migration_failures
    end

    def init_project_migration_logging(
      logfile_name = options[:migration_logfile_name], log_level = Logger::INFO)
      fields = { date: Time.now.strftime(::Storage::RebalanceScript::MIGRATION_TIMESTAMP_FORMAT) }
      logfile_name = format(logfile_name, **fields)
      logdir_path = options[:logdir_path]
      FileUtils.mkdir_p logdir_path
      logfile_path = File.join(logdir_path, logfile_name)
      FileUtils.touch logfile_path
      logger = Logger.new(logfile_path, level: log_level)
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

    def migration_error_log
      @migration_error_log ||= init_project_migration_logging(options[:migration_error_logfile_name], Logger::ERROR)
    end
  end
end

# Re-open the Storage module to add the Helpers module
module Storage
  # Helper methods
  module Helpers
    ISO8601_FRACTIONAL_SECONDS_LENGTH = 3
    BYTES_CONVERSIONS = {
      'B': 1024,
      'KB': 1024 * 1024,
      'MB': 1024 * 1024 * 1024,
      'GB': 1024 * 1024 * 1024 * 1024,
      'TB': 1024 * 1024 * 1024 * 1024 * 1024
    }.freeze
    DEFAULT_TERMINAL_LINE_HEIGHT = 45
    DEFAULT_TERMINAL_COLUMN_WIDTH = 80

    def execute_remote_command(hostname, command)
      execute_command(format(options[:ssh_command], hostname: hostname, command: command))
    end

    def execute_command(command)
      log.debug "Executing command: #{command}"
      `#{command}`.strip
    end

    def symbolize_keys_deep!(memo)
      memo.keys.each do |key|
        symbolized_key = key.respond_to?(:to_sym) ? key.to_sym : key
        memo[symbolized_key] = memo.delete(key) # Preserve order even when key == symbolized_key
        symbolize_keys_deep!(memo[symbolized_key]) if memo[symbolized_key].is_a?(Hash)
      end
    end

    def to_filesize(bytes)
      BYTES_CONVERSIONS.each_pair do |denomination, threshold|
        return "#{(bytes.to_f / (threshold / 1024)).round(2)} #{denomination}" if bytes < threshold
      end
    end

    def password_prompt(prompt = 'Enter password: ')
      $stdout.write(prompt)
      $stdout.flush
      $stdin.noecho(&:gets).chomp
    ensure
      $stdin.echo = true
      # $stdout.flush
      $stdout.ioflush
      $stdout.write "\r" + (' ' * prompt.length) + "\n"
      $stdout.flush
    end

    def set_api_token_or_else(&on_failure)
      prompt = options[:password_prompt]
      env_variable_name = options[:token_env_variable_names][options[:env]]
      token = ENV.fetch(env_variable_name, nil)
      if token.nil? || token.empty?
        log.warn "No #{env_variable_name} variable set in environment"
        token = password_prompt(prompt)
        if token.nil? || token.empty?
          raise 'Failed to get token' unless block_given?

          on_failure.call
        end
      end
      gitlab_api_client.required_headers['Private-Token'] = token
    end

    def console_node_hostname
      console_nodes = options[:console_nodes]
      environment = options[:env]
      fqdn = console_nodes.include?(environment) ? console_nodes[environment] : console_nodes[:production]
      abort 'No console node is configured' if fqdn.nil? || fqdn.empty?

      fqdn
    end

    def get_api_url(resource_path)
      raise 'No such resource path is configured' unless options.include?(resource_path)

      endpoints = options[:api_endpoints]
      environment = options[:env]
      endpoint = endpoints.include?(environment) ? endpoints[environment] : endpoints[:production]
      abort 'No api endpoint url is configured' if endpoint.nil? || endpoint.empty?

      [endpoint, options[resource_path]].join('/')
    end

    def all_projects_specify_destination?(projects)
      return false if projects.empty? || !projects.respond_to?(:all?)

      projects.all? { |project| project.include?(:destination_repository_storage) }
    end

    def get_columns
      if options[:use_tty_display_settings]
        _rows, columns = IO.console.winsize
        columns -= ::Storage::RebalanceScript::LOG_META_INFO_LENGTH
      else
        columns = ::Storage::RebalanceScript::DISPLAY_WIDTH
      end
      columns
    end

    def loop_with_progress_until(timeout = ::Storage::RebalanceScript::DEFAULT_TIMEOUT, &block)
      progress_character = ::Storage::RebalanceScript::PROGRESS_FULL_BRAILLE
      spinner_characters = ::Storage::RebalanceScript::PROGRESS_BRAILLES
      seconds_per_spin = ::Storage::RebalanceScript::SECONDS_PER_SPIN
      spinner_pause_interval_seconds = 1 / spinner_characters.length.to_f
      columns = get_columns
      bar_characters = ''
      iteration = 0
      start = Time.now.to_i
      loop do
        break if block_given? && block.call == true

        elapsed = Time.now.to_i - start
        raise Timeout, "Timed out after #{elapsed} seconds" if elapsed >= timeout

        seconds_per_spin.times do
          spinner_characters.each do |character|
            progress_log.info(format('%s%s', bar_characters, character))
            sleep(spinner_pause_interval_seconds)
          end
        end
        iteration += 1
        bar_characters = progress_character * (iteration % columns)
        progress_log.info(format('%s%s', bar_characters, progress_character))
        if (iteration % columns).zero?
          bar_characters = ''
          $stdout.write("\n")
        elsif log.level == Logger::DEBUG
          $stdout.write("\n")
        end
        $stdout.flush
      end
    ensure
      puts "\n"
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
        @parser.banner = "Usage: #{$PROGRAM_NAME} [options] <source_shard> <destination_shard>"
        @parser.separator ''
        @parser.separator 'Options:'
        define_head
        define_dry_run_option
        define_projects_option
        define_json_option
        define_csv_option
        define_move_amount_option
        define_skip_option
        define_per_page_option
        define_wait_option
        define_max_failures_option
        define_retry_known_failures_option
        define_limit_option
        define_tty_option
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

      def define_dry_run_option
        description = 'Show what would have been done; default: yes'
        @parser.on('-d', '--dry-run=[yes/no]', description) do |dry_run|
          @options[:dry_run] = !dry_run.match?(/^(no|false)$/i)
        end
      end

      def define_projects_option
        description = 'Select specific projects to migrate'
        @parser.on('--projects=<project_id,...>', Array, description) do |projects|
          @options[:projects] ||= []
          unless projects.respond_to?(:all?) && projects.all? { |s| resembles_integer? s }
            message = 'Argument given for --projects must be a list of one or more integers'
            raise OptionParser::InvalidArgument, message
          end

          projects.each do |project|
            if (project_id = project.to_i).positive?
              @options[:projects].push({ id: project_id })
            end
          end
        end
      end

      def define_json_option
        description = 'Absolute path to JSON file enumerating projects ids'
        @parser.on('--json=<file_path>', description) do |file_path|
          unless File.exist? file_path
            message = 'Argument given for --json must be a path to an existing file'
            raise OptionParser::InvalidArgument, message
          end

          # TODO: Refactor to a helper method
          @options[:projects] ||= []
          projects = JSON.parse(IO.read(file_path))['projects']
          projects.each do |project|
            @options[:projects].push(project.transform_keys!(&:to_sym))
          end
        end
      end

      def define_csv_option
        description = 'Absolute path to CSV file enumerating projects ids'
        @parser.on('--csv=<file_path>', description) do |file_path|
          unless File.exist? file_path
            message = 'Argument given for --csv must be an absolute path to an existing file'
            raise OptionParser::InvalidArgument, message
          end

          # TODO: Refactor to a helper method
          @options[:projects] ||= []
          projects = CSV.new(file_path).to_a
          projects.collect do |project_values|
            project = {}
            project_values.each_with_index do |value, i|
              project[::Storage::RebalanceScript::PROJECT_FIELDS[i]] = value
            end
            project
          end
          @options[:projects].concat(projects)
        end
      end

      def define_move_amount_option
        description = "Gigabytes of repo data to move; default: #{@options[:move_amount]}, or " \
          'largest single repo if 0'
        @parser.on('-m', '--move-amount=<n>', Integer, description) do |move_amount|
          abort 'Size too large' if move_amount > 16_000
          # Convert given gigabytes to bytes
          @options[:move_amount] = (move_amount * 1024 * 1024 * 1024)
        end
      end

      def define_skip_option
        description = 'Skip specific project(s)'
        @parser.on('--skip=<project_id,...>', Array, description) do |project_identifiers|
          @options[:excluded_projects] ||= Set.new
          if project_identifiers.respond_to?(:all?) &&
              project_identifiers.all? { |s| resembles_integer? s }
            positive_numbers = project_identifiers.map(&:to_i).delete_if { |i| !i.positive? }
            @options[:excluded_projects] |= positive_numbers.uniq
          else
            message = 'Argument given for --skip must be a list of one or more integers'
            raise OptionParser::InvalidArgument, message
          end
        end
      end

      def define_per_page_option
        description = "Projects per page to request; default: #{@options[:projects_per_page]}"
        @parser.on('--per-page=<n>', Integer, description) do |per_page|
          abort 'Given projects per-page must be between 1 and 100' if per_page < 1 || per_page > 100
          @options[:projects_per_page] = per_page
        end
      end

      def define_wait_option
        description = "Timeout in seconds for migration completion; default: " \
          "#{@options[:repository_storage_update_timeout]}"
        @parser.on('-w', '--wait=<n>', Integer, description) do |wait|
          @options[:repository_storage_update_timeout] = wait
        end
      end

      def define_max_failures_option
        description = "Maximum failed migrations; default: #{@options[:max_failures]}"
        @parser.on('-f', '--max-failures=<n>', Integer, description) do |failures|
          @options[:max_failures] = failures
        end
      end

      def define_retry_known_failures_option
        description = "Retry known recorded migration failures; default: #{@options[:retry_known_failures]}"
        @parser.on('-f', '--retry-known-failures', description) do
          @options[:max_failures] = true
        end
      end

      def define_limit_option
        description = "Maximum migrations; default: #{@options[:limit]}"
        @parser.on('-l', '--limit=<n>', Integer, description) do |limit|
          @options[:limit] = limit
        end
      end

      def define_include_mirrors_option
        @parser.on('-M', '--include-mirrors', 'Include mirror repositories') do |include_mirrors|
          @options[:include_mirrors] = true
        end
      end

      def define_tty_option
        @parser.on('--tty', 'Format progress display using tty settings') do
          @options[:use_tty_display_settings] = true
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

      def resembles_integer?(obj)
        ::Storage::RebalanceScript::INTEGER_PATTERN.match?(obj.to_s)
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
      # TODO: Handle with a helper method
      unless STDIN.tty? || STDIN.closed?
        projects = CSV.new(file_path).to_a
        projects.each { |project| opt.options[:projects].push(Project.new(*project)) }
      end
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

# Re-open the Storage module to define the GitLabClient class
module Storage
  # Define the GitLabClient class
  class GitLabClient
    DEFAULT_RESPONSE = OpenStruct.new(code: 400, body: '{}') unless defined? ::Storage::GitLabClient::DEFAULT_RESPONSE
    include ::Storage::Logging
    attr_reader :options
    attr_accessor :required_headers
    def initialize(options)
      @options = options
      log.level = @options[:log_level]
      @required_headers = {}
    end

    def get(url, opts = {})
      request(Net::HTTP::Get, url, opts)
    end

    def post(url, opts = {})
      opts.update(headers: { 'Content-Type': 'application/json' }) if opts.fetch(
        :body, nil).respond_to?(:[]) && !opts.fetch(:headers, {}).include?('Content-Type')
      request(Net::HTTP::Post, url, opts)
    end

    def put(url, opts = {})
      request(Net::HTTP::Put, url, opts)
    end

    private

    def request(klass, url, opts = {})
      uri = URI(url)
      parameters = opts.fetch(:parameters, {}).transform_keys(&:to_s).transform_values(&:to_s)
      uri.query = URI.encode_www_form(parameters) unless parameters.empty?
      client = Net::HTTP.new(uri.host, uri.port)
      client.use_ssl = (uri.scheme == 'https')
      headers = opts.fetch(:headers, {}).merge(required_headers)
      request = klass.new(uri, headers)
      invoke(client, request, opts)
    end

    # rubocop: disable Metrics/AbcSize
    def invoke(client, request, opts = {})
      body = opts[:body]
      request.body = body.respond_to?(:bytesize) ? body : body.to_json unless body.nil?
      debug_request(request)

      response = DEFAULT_RESPONSE
      result = {}
      error = nil
      status = response.code
      begin
        response, status = execute(client, request)
      rescue Errno::ECONNREFUSED => e
        log.error e.to_s
        error = e
      rescue EOFError => e
        log.error "Encountered EOF reading from network socket"
        error = e
      rescue OpenSSL::SSL::SSLError => e
        log.error "Socket error: #{e} (#{e.class})"
        error = e
      rescue Net::ReadTimeout => e
        log.error "Timed out reading"
        error = e
      rescue Net::OpenTimeout => e
        log.error "Timed out opening connection"
        error = e
      rescue Net::HTTPBadResponse => e
        log.error e.message
        error = e
        status = e.response.code.to_i if e.respond_to?(:response)
      rescue Net::HTTPUnauthorized => e
        log.error e.message
        error = e
        status = e.response.code.to_i if e.respond_to?(:response)
      rescue Net::HTTPClientException => e
        log.error e.message
        error = e
        status = e.response.code.to_i if e.respond_to?(:response)
      rescue Net::HTTPClientError => e
        log.error "Unexpected HTTP client error: #{e.message} (#{e.class})"
        error = e
        status = e.response.code.to_i if e.respond_to?(:response)
      rescue Net::ProtocolError => e
        log.error "Unexpected HTTP protocol error: #{e.message} (#{e.class})"
        error = e
        status = e.response.code.to_i if e.respond_to?(:response)
      rescue Net::HTTPFatalError => e
        log.error "Unexpected HTTP fatal error: #{e.message} (#{e.class})"
        error = e
      rescue IOError => e
        log.error "Unexpected IO error: #{e} (#{e.class})"
        error = e
      rescue StandardError => e
        log.error "Unexpected error: #{e} (#{e.class})"
        log.error e.exception_type if e.respond_to? :exception_type
        error = e
      end

      headers = {}
      response.each_header { |key, value| headers[key] = value.split(', ') }
      result, error = deserialize(response) if error.nil?

      [result, error, status, headers]
    end
    # rubocop: enable Metrics/AbcSize

    def execute(client, request)
      response = client.request(request)
      log.debug "Response status code: #{response.code}"
      response.value
      [response, response.code.to_i]
    end

    def deserialize(response)
      result = nil
      error = nil
      begin
        response_data = response.body
        result = JSON.parse(response_data)
      rescue JSON::ParserError => e
        n = response.body.length
        message = "Could not parse #{n} bytes of json serialized data from #{uri.path}"
        if n > 65536
          log.warn message
        else
          log.error message
          error = e
        end
      rescue IOError => e
        log.error format('Unexpected IO error: %<error>s (%<error_class>s)', error: e, error_class: e.class)
        error = e
      rescue StandardError => e
        log.error format(
          'Unexpected error: %<error>s (%<error_class>s%<error_type>s)',
          error: e, error_class: e.class,
          error_type: e.respond_to?(:exception_type) ? format('/%s', e.exception_type) : '')
        error = e
      end
      [result, error]
    end
  end
end

# Re-open the Storage module to define the Rebalancer class
module Storage
  # The Rebalancer class
  class Rebalancer
    include ::Storage::Logging
    include ::Storage::Helpers
    attr_reader :options, :gitlab_api_client, :migration_errors
    def initialize(options)
      @options = options
      @gitlab_api_client = Storage::GitLabClient.new(@options)
      @migration_errors = []
      log.level = @options[:log_level]
      @pagination_indices = {}
    end

    def log_migration(project)
      log_artifact = {
        id: project[:id],
        path: project[:disk_path],
        source: project[:repository_storage],
        destination: options[:destination_shard],
        date: DateTime.now.iso8601(ISO8601_FRACTIONAL_SECONDS_LENGTH)
      }
      migration_log.info log_artifact.to_json
    end

    def log_migration_error(project, error)
      log_artifact = error.merge(
        source: project[:repository_storage],
        destination: options[:destination_shard],
        date: DateTime.now.iso8601(ISO8601_FRACTIONAL_SECONDS_LENGTH)
      )
      migration_error_log.error log_artifact.to_json
    end

    def fetch_project(project_id)
      return {} if project_id.nil? || project_id.to_s.empty?

      url = format(get_api_url(:projects_by_id_api_uri), project_id: project_id)
      project, error, status, _headers = gitlab_api_client.get(
        url, parameters: { statistics: true })
      raise error unless error.nil?

      raise "Invalid response status code: #{status}" unless [200].include?(status)

      raise "Failed to get project id: #{project_id}" if project.nil? || project.empty?

      symbolize_keys_deep!(project)
      project
    end

    # Execute remote script to fetch largest projects
    def fetch_largest_projects(next_page = false)
      source_shard = options[:source_shard]
      url = get_api_url(:projects_api_uri)
      parameters = {
        order_by: 'repository_size',
        statistics: true,
        repository_storage: source_shard,
        per_page: options[:projects_per_page]
      }
      parameters['page'] = @pagination_indices[__method__] if @pagination_indices.include?(__method__)
      projects, error, status, headers = gitlab_api_client.get(url, parameters: parameters)
      raise error unless error.nil?

      @pagination_indices[__method__] = headers['x-next-page'].first

      raise "Invalid response status code: #{status}" unless [200].include?(status)

      raise "Unexpected response: #{projects}" if projects.nil? || projects.empty?

      projects.each { |project| symbolize_keys_deep!(project) }
      projects
    end

    def fetch_repository_storage_move(project, repository_storage_move)
      url = format(
        get_api_url(:projects_repository_storage_move_api_uri),
        project_id: project[:id],
        repository_storage_move_id: repository_storage_move[:id])
      move, error, status, _headers = gitlab_api_client.get(url)
      raise error unless error.nil?

      raise "Invalid response status code: #{status}" unless [200].include?(status)

      raise "Unexpected response: #{move}" unless move.fetch('project', {}).fetch('id', nil) == project[:id]

      symbolize_keys_deep!(move)
      move
    end

    def fetch_repository_storage_moves(project)
      url = format(get_api_url(:projects_repository_storage_moves_api_uri), project_id: project[:id])
      moves, error, status, _headers = gitlab_api_client.get(url)
      raise error unless error.nil?

      raise "Invalid response status code: #{status}" unless [200].include?(status)

      raise "Unexpected response: #{moves}" if moves.nil?

      moves.each { |element| symbolize_keys_deep!(element) }
      moves
    end

    def create_repository_storage_move(project, destination)
      url = format(get_api_url(:projects_repository_storage_moves_api_uri), project_id: project[:id])
      move, error, status, _headers = gitlab_api_client.post(
        url, body: { destination_storage_name: destination })
      raise error unless error.nil?

      raise "Invalid response status code: #{status}" unless [200, 201].include?(status)

      raise "Unexpected response: #{move}" unless move.fetch('project', {}).fetch('id', nil) == project[:id]

      symbolize_keys_deep!(move)
      move
    end

    def wait_for_repository_storage_move(project, repository_storage_move, opts = {})
      project_repository_move_states = options[:project_repository_move_states].merge(opts)
      timeout = options[:repository_storage_update_timeout]
      success_state = project_repository_move_states[:success]
      failure_state = project_repository_move_states[:failure]

      begin
        loop_with_progress_until(timeout) do
          with_log_level(Logger::INFO) do
            repository_move = fetch_repository_storage_move(project, repository_storage_move)
            repository_move_state = repository_move.fetch(:state, nil)&.to_sym
            if repository_move_state == failure_state
              raise ServiceFailure.new(
                'Noticed service failure during repository replication', repository_move)
            end
            repository_move_state == success_state
          end
        end
      rescue Timeout => e
        log.warn "Gave up waiting for repository storage move to reach state: #{success_state}: #{e.message}"
      end
    end

    def verify_source(project)
      return if project[:repository_storage] == options[:source_shard]

      raise ShardMismatch, "Repository for project id: #{project[:id]} is on shard: " \
        "#{project[:repository_storage]} not #{options[:source_shard]}"
    end

    def summarize(total)
      log_separator
      log.info "Done"
      if total.positive?
        if options[:dry_run]
          log.info "[Dry-run] Would have processed #{to_filesize(total)} of data"
        else
          log.info "Processed #{to_filesize(total)} of data"
        end
      end
      return if options[:dry_run]

      log.info "Finished migrating projects from #{options[:source_shard]} to " \
        "#{options[:destination_shard]}"
      if migration_errors.empty?
        log.info "No errors encountered during migration"
      else
        log.error "Encountered #{migration_errors.length} errors:"
        log.error JSON.pretty_generate(migration_errors)
      end
    end

    def repository_replication_already_in_progress?(project)
      log.debug "Checking for existing repository replications for project id #{project[:id]}"
      fetch_repository_storage_moves(project).any? do |move|
        options[:project_repository_move_states][:in_progress].include?(move[:state]&.to_sym)
      end
    end

    # rubocop: disable Metrics/AbcSize
    def schedule_repository_replication(project)
      verify_source(project)
      if repository_replication_already_in_progress?(project)
        log.warn "Repository replication for project id #{project[:id]} already in progress; skipping"
        return
      end

      destination = options[:destination_shard] || project[:destination_repository_storage]
      log_separator
      log.info "Scheduling repository replication to #{destination} for project id: #{project[:id]}"
      log.info "  Project path: #{project[:path_with_namespace]}"
      log.info "  Current shard name: #{project[:repository_storage]}"
      log.info "  Disk path: #{project[:disk_path]}" if project.include?(:disk_path)
      if project.include?(:statistics)
        log.info "  Repository size: #{to_filesize(project[:statistics][:repository_size])}"
      elsif project.include?(:size)
        log.info "  Repository size: #{project[:size]}"
      end

      if options[:dry_run]
        log.info "[Dry-run] Would have scheduled repository replication for project id: #{project[:id]}"
        return
      end

      repository_storage_move = create_repository_storage_move(project, destination)
      wait_for_repository_storage_move(project, repository_storage_move)
      post_migration_project = project.merge(fetch_project(project[:id]))
      if post_migration_project[:repository_storage] == destination
        log.info "Success moving project id: #{project[:id]}"
      else
        raise MigrationTimeout, "Timed out waiting for migration of " \
          "project id: #{post_migration_project[:id]}"
      end

      log.info "Migrated project id: #{post_migration_project[:id]}"
      log.debug "  Project path: #{post_migration_project[:path_with_namespace]}"
      log.debug "  Current shard name: #{post_migration_project[:repository_storage]}"
      log.debug "  Disk path: #{post_migration_project[:disk_path]}" if post_migration_project.include?(:disk_path)
      log_migration(project)
    end
    # rubocop: enable Metrics/AbcSize

    def move_project(project)
      project_id = project[:id]
      project_info = fetch_project(project_id)
      project.update(project_info)

      schedule_repository_replication(project)
    rescue NoCommits => e
      log_and_record_migration_error(e, project)
    rescue ShardMismatch => e
      log.error "Wrong shard given for project id: #{project_id}"
      log_and_record_migration_error(e, project)
    rescue MigrationTimeout => e
      log.error "Timed out migrating project id: #{project_id}"
      log_and_record_migration_error(e, project)
    rescue ServiceFailure => e
      log.error "Service error migrating project id: #{project_id}"
      log_and_record_migration_error(e, project)
    rescue Net::HTTPFatalError => e
      log.error "Unexpected server error migrating project id: #{project_id}"
      log_and_record_migration_error(e, project)
    rescue Net::HTTPClientException => e
      log.error "Unexpected client error migrating project id: #{project_id}"
      log_and_record_migration_error(e, project)
    rescue StandardError => e
      log.error "Unexpected error migrating project id #{project_id}: #{e} (#{e.class})"
      log_and_record_migration_error(e, project, include_backtrace: true, persist: false)
    end

    def get_repository_size(project)
      size = project.fetch(:statistics, {}).fetch(:repository_size, nil)
      raise "Absent field 'statistics.repository_size' for project id: #{project[:id]}" if size.nil?

      size
    end

    def exclude_known_failures
      failed_reprojectories = load_migration_failures.collect { |failure| failure.fetch(:project_id, nil) }
      failed_reprojectories.compact!
      log.info "Filtering #{failed_reprojectories.length} known failed project repositories"
      log.debug "Known failed project repositories: #{failed_reprojectories}"
      options[:excluded_projects] |= failed_reprojectories
    end

    def get_projects
      projects = options.fetch(:projects, []).map { |project| fetch_project(project[:id]) }
      if projects.empty?
        exclude_known_failures unless options[:retry_known_failures]
        next_page = false
        # This loop is only here to ensure that if projects are excluded
        # (typicaly because of previous known replication failures) from a
        # returned page of projects, that a subsequent page is requested in
        # the case that the current page is full of nothing but projects which
        # are presumed to be doomed to fail their replication operation.
        loop do
          log.info format('Fetching %slargest projects', next_page ? 'next page of ' : '')
          projects = fetch_largest_projects(next_page)
          # When there are no more projects in the API result set:
          break if projects.empty?

          projects.reject! { |project| options[:excluded_projects].include?(project[:id]) }
          # When there are non-failed projects in the API result set:
          break unless projects.empty?

          # When there are no non-failed projects in the API result set,
          # get the next page.
          next_page = true
        end
      end
      projects = projects[0...options[:limit]] if options[:limit].positive?
      projects
    end

    def paginate_projects(projects, &block)
      return projects unless block_given?

      loop do
        break if projects.nil? || projects.empty?

        project = projects.shift
        break if project.nil?

        next if project.empty?

        yield project
        projects = get_projects if projects.empty?
      end
    end

    def move_projects(min_amount = options[:move_amount], limit = options[:limit])
      log.debug "Project migration validation timeout: " \
        "#{options[:repository_storage_update_timeout]} seconds"

      moved_projects_count = 0
      total_bytes_moved = 0
      projects = get_projects

      paginate_projects(projects) do |project|
        repository_size_bytes = get_repository_size(project)
        move_project(project)
        if migration_errors.length >= options[:max_failures]
          log.error "Failed too many times"
          break
        end
        moved_projects_count += 1
        total_bytes_moved += repository_size_bytes
        break if limit.positive? && moved_projects_count >= limit
        break if min_amount.positive? && total_bytes_moved > min_amount
      end
      total_bytes_moved
    end

    def rebalance
      migration_log
      limit = options[:limit]
      move_amount_bytes = options[:move_amount]
      if limit.positive?
        log.info "Will move #{limit} projects"
      elsif move_amount_bytes.zero?
        options[:limit] = 1
        log.info 'Option --move-amount not specified, will only move 1 project...'
      else
        log.info "Will move at least #{to_filesize(move_amount_bytes)} worth of data"
      end

      total_bytes_moved = move_projects
      summarize(total_bytes_moved)
      nil # Signifies no error
    end
  end
  # class Rebalancer
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

      unless all_projects_specify_destination?(args[:projects])
        source_shard = demand(args, :source_shard, true)
        destination_shard = demand(args, :destination_shard, true)
        raise UserError, 'Destination and source gitaly shard may not be the same' if source_shard == destination_shard
      end

      rebalancer = ::Storage::Rebalancer.new(args)
      rebalancer.set_api_token_or_else do
        raise UserError, 'Cannot proceed without a GitLab admin API private token'
      end
      rebalancer.rebalance
    rescue UserError => e
      abort e.message
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

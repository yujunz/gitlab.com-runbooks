#! /usr/bin/env ruby

# Execution example:
#
# $ bundle exec scripts/uploads_cleanup.rb --verbose --disk-path='@hashed/07/4e/074e3326b9850801cc2e592812cba397a2ffab519e70f2556d969621bdbb10ca' --dry-run=yes
# 2020-03-13 09:07:30 INFO  [Dry-run] This is only a dry-run -- write operations will be logged but not executed
# 2020-03-13 09:07:30 DEBUG Invoking command: ssh sidekiq-besteffort-01-sv-gprd.c.gitlab-production.internal 'sudo find /opt/gitlab/embedded/service/gitlab-rails/public/uploads/@hashed/07/4e/074e3326b9850801cc2e592812cba397a2ffab519e70f2556d969621bdbb10ca -depth -mindepth 1'
# 2020-03-13 09:07:32 INFO  [Dry-run] Would have invoked command: ssh  'rm -rf /opt/gitlab/embedded/service/gitlab-rails/public/uploads/@hashed/07/4e/074e3326b9850801cc2e592812cba397a2ffab519e70f2556d969621bdbb10ca/tmp/cache/1536077216-16440-0022-5930/image001.png'
# 2020-03-13 09:07:32 INFO  [Dry-run] Would have invoked command: ssh  'rm -rf /opt/gitlab/embedded/service/gitlab-rails/public/uploads/@hashed/07/4e/074e3326b9850801cc2e592812cba397a2ffab519e70f2556d969621bdbb10ca/tmp/cache/1536077216-16440-0022-5930'
# 2020-03-13 09:07:32 INFO  [Dry-run] Would have invoked command: ssh  'rm -rf /opt/gitlab/embedded/service/gitlab-rails/public/uploads/@hashed/07/4e/074e3326b9850801cc2e592812cba397a2ffab519e70f2556d969621bdbb10ca/tmp/cache'
# 2020-03-13 09:07:32 INFO  [Dry-run] Would have invoked command: ssh  'rm -rf /opt/gitlab/embedded/service/gitlab-rails/public/uploads/@hashed/07/4e/074e3326b9850801cc2e592812cba397a2ffab519e70f2556d969621bdbb10ca/tmp/work'
# 2020-03-13 09:07:32 INFO  [Dry-run] Would have invoked command: ssh  'rm -rf /opt/gitlab/embedded/service/gitlab-rails/public/uploads/@hashed/07/4e/074e3326b9850801cc2e592812cba397a2ffab519e70f2556d969621bdbb10ca/tmp'
#
# Directory not found example:
#
# $ bundle exec scripts/uploads_cleanup.rb --verbose --host=sidekiq-besteffort-02-sv-gprd.c.gitlab-production.internal --disk-path='@hashed/07/4e/074e3326b9850801cc2e592812cba397a2ffab519e70f2556d969621bdbb10ca' --dry-run=yes
# 2020-03-13 09:09:56 INFO  [Dry-run] This is only a dry-run -- write operations will be logged but not executed
# 2020-03-13 09:09:56 DEBUG Invoking command: ssh sidekiq-besteffort-02-sv-gprd.c.gitlab-production.internal 'sudo find /opt/gitlab/embedded/service/gitlab-rails/public/uploads/@hashed/07/4e/074e3326b9850801cc2e592812cba397a2ffab519e70f2556d969621bdbb10ca -depth -mindepth 1'
# find: '/opt/gitlab/embedded/service/gitlab-rails/public/uploads/@hashed/07/4e/074e3326b9850801cc2e592812cba397a2ffab519e70f2556d969621bdbb10ca': No such file or directory

require 'logger'
require 'optparse'

# Define the Uploads module
module Uploads
  # Define the CleanupScript module
  module CleanupScript
    # Configuration defaults
    module Config
      DEFAULTS = {
        dry_run: true,
        hostname: 'sidekiq-besteffort-01-sv-gprd.c.gitlab-production.internal',
        uploads_dir_path: '/opt/gitlab/embedded/service/gitlab-rails/public/uploads',
        valid_operations: [:delete],
        operation: nil,
        remote_command: "ssh %{hostname} '%{command}'",
        find: 'sudo find %{path} -depth -mindepth 1 -mmin +%{minutes}',
        interval_minutes: 5,
        log_level: Logger::INFO
      }.freeze
    end

    LOG_TIMESTAMP_FORMAT = '%Y-%m-%d %H:%M:%S'.freeze
  end
end

# Re-open the Uploads module to add the LoggingSupport module
module Uploads
  # This module defines logging methods
  module LoggingSupport
    def initialize_log
      STDOUT.sync = true
      timestamp_format = ::Uploads::CleanupScript::LOG_TIMESTAMP_FORMAT
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
      return unless log.level == Logger::DEBUG

      lines.each { |line| log.debug line unless line.nil? || line.empty? }
    end
  end
end

# Re-open the registry module to add CommandLineSupport module
module Uploads
  # Support for command line arguments
  module CommandLineSupport
    # Options parser
    class Options
      attr_reader :parser, :options

      def initialize
        @parser = OptionParser.new
        @options = ::Uploads::CleanupScript::Config::DEFAULTS.dup
        define_options
      end

      def define_options
        @parser.banner = "Usage: #{$PROGRAM_NAME} [options]"
        define_dry_run_option
        define_host_option
        define_path_option
        define_operation_option
        define_verbose_option
        define_tail
      end

      def define_dry_run_option
        description = 'Show what would have been done; default: yes'
        @parser.on('-d', '--dry-run=[yes/no]', description) do |dry_run|
          raise OptionParser::InvalidArgument unless dry_run.match?(/^(yes|no)$/i)

          @options[:dry_run] = false if dry_run.match?(/^no$/i)
        end
      end

      def define_host_option
        description = 'The host on which to clean-up uploads'
        @parser.on('-h', '--host=<fqdn>', description) do |fqdn|
          @options[:hostname] = fqdn
        end
      end

      def define_path_option
        description = 'The path of the hashed storage repository directory'
        @parser.on('-p', '--disk-path=<path>', description) do |path|
          @options[:disk_path] = path
        end
      end

      def define_interval_option
        description = 'Minutes older than which selected files must be'
        @parser.on('-n', '--older-than=<minutes>', Integer, description) do |interval|
          @options[:interval_minutes] = interval
        end
      end

      def define_operation_option
        ops = ::Uploads::CleanupScript::Config::DEFAULTS[:valid_operations]
        description = 'Operation to invoke on each result'
        @parser.on('-O', "--operation=<#{ops.join('|')}>", description) do |arg|
          op = arg.to_sym
          raise OptionParser::InvalidArgument unless ops.include?(op)

          @options[:operation] = op
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

    def parse(args)
      opt = Options.new
      args.push('-?') if args.empty?
      opt.parser.parse!(opt.parser.order!(args) {})
      opt.options
    rescue OptionParser::InvalidArgument, OptionParser::InvalidOption,
           OptionParser::MissingArgument, OptionParser::ParseError => e
      puts e
      puts opt.parser
      exit
    rescue OptionParser::AmbiguousOption => e
      abort e.message
    end
  end
end

# Re-open the Uploads module to add SelectorMethods module
module Uploads
  # SelectorMethods module
  module SelectorMethods
    def get_non_empty_with_only_tmp_dir_files(hostname, path)
      tmp_dir_path = File.join(path, 'tmp')
      command = format(options[:find], path: path, minutes: options[:interval_minutes])
      remote_command = build_remote_command(hostname, command)
      results = invoke(remote_command).split
      if !results.empty? && results.all? { |path| path.start_with?(tmp_dir_path) }
        results
      else
        []
      end
    end
  end
end

# Re-open the Uploads module to add CommandSupport module
module Uploads
  # RemoteSupport module
  module CommandSupport
    def build_remote_command(hostname, command)
      format(options[:remote_command], hostname: hostname, command: command)
    end

    def invoke(command)
      debug_command(command)
      `#{command}`.strip
    end

    def safely_invoke_find_with_operation(hostname, path, operation)
      return if operation.nil? || !options[:valid_operations].include?(operation)

      command = format(options[:find], path: path, minutes: options[:interval_minutes])
      command << " -#{operation}"
      remote_command = build_remote_command(hostname, command)

      if options[:dry_run]
        log.info "[Dry-run] Would have invoked command: #{remote_command}"
      else
        log.info "Invoking command: #{remote_command}"
        invoke(remote_command)
      end
      nil
    end
  end
end

# Re-open the Uploads module to add Cleaner class
module Uploads
  # Cleaner class
  class Cleaner
    include ::Uploads::LoggingSupport
    include ::Uploads::SelectorMethods
    include ::Uploads::CommandSupport
    attr_reader :options
    def initialize(opts)
      @options = opts
      @hostname = opts[:hostname]
      @path = File.join(opts[:uploads_dir_path], opts[:disk_path])
      @operation = opts[:operation]
      log.level = opts[:log_level]
    end

    def clean
      paths = get_non_empty_with_only_tmp_dir_files(@hostname, @path)
      log.debug "Found paths:"
      debug_lines(paths)
      safely_invoke_find_with_operation(@hostname, @path, @operation) unless paths.empty?
    end
  end
end

# Re-open the Uploads module to add CleanupScript module
module Uploads
  # Script module
  module CleanupScript
    include ::Uploads::LoggingSupport
    include ::Uploads::CommandLineSupport

    def main(args = parse(ARGV))
      log.level = args[:log_level]
      dry_run_notice if args[:dry_run]
      cleaner = Uploads::Cleaner.new(args)
      cleaner.clean
    rescue SystemExit
      exit
    rescue Interrupt => e
      $stdout.write "\r\n#{e.class}\n"
      $stdout.flush
      exit 0
    end
  end
end

Object.new.extend(::Uploads::CleanupScript).main if $PROGRAM_NAME == __FILE__

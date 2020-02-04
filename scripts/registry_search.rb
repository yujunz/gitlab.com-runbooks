#! /usr/bin/env ruby
# frozen_string_literal: true

# Google Cloud Storage authorization
#
# First things first: Create a key for the gitlab-object-storage-ro service account.
# You may need to set a new Access Control List for the service account in order to
# enable READ access to the object buckets.
# (See https://cloud.google.com/storage/docs/gsutil/commands/acl#ch-examples_1 for more
# information.)
#
# gcloud config set project gitlab-production
# gsutil acl ch -u gitlab-object-storage-ro@gitlab-production.iam.gserviceaccount.com:READ gs://gitlab-gprd-registry
# gcloud iam service-accounts keys create ~/gitlab-object-storage-ro.json --iam-account gitlab-object-storage-ro@gitlab-production.iam.gserviceaccount.com
#
# Execution:
#
# bundle exec scripts/registry_search.rb --path=docker/registry/v2/repositories/vulcans/vulcan_instance/master/data/_manifests/tags/8342/
# bundle exec scripts/registry_search.rb --path=docker/registry/v2/repositories/vulcans/vulcan_instance/master/data/_manifests/tags/
#
# In order to perform any mutator operation such as a create, update, or delete, you will
# need to add WRITE privileges to the service account.
#
# gsutil acl ch -u gitlab-object-storage@gitlab-production.iam.gserviceaccount.com:WRITE gs://gitlab-gprd-registry
# gcloud iam service-accounts keys create ~/gitlab-object-storage-rw.json --iam-account gitlab-object-storage-ro@gitlab-production.iam.gserviceaccount.com
#
# To delete all files older than 30 days:
#
# bundle exec scripts/registry_search.rb --dry-run=yes --age=30 --operation=delete --path=docker/registry/v2/repositories/vulcans/vulcan_instance/master/data/_manifests/tags/ --key=~/gitlab-object-storage-rw.json
#

require 'date'
require 'json'
require 'logger'
require 'optparse'

require 'google/cloud/storage'

# Define the registry module
module Registry
  # This module defines logging methods
  module LoggingSupport
    LOG_TIMESTAMP_FORMAT = '%Y-%m-%d %H:%M:%S'

    def initialize_log
      STDOUT.sync = true
      log = Logger.new STDOUT
      log.level = Logger::INFO
      log.formatter = proc do |level, t, _name, msg|
        fields = { timestamp: t.strftime(LOG_TIMESTAMP_FORMAT), level: level, msg: msg }
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

# Re-open the registry module to add Config module
module Registry
  # Configuration defaults
  module Config
    DEFAULTS = {
      dry_run: true,
      project: 'gitlab-production',
      key_file_path: '~/gitlab-object-storage-ro.json',
      bucket: 'gitlab-gprd-registry',
      age: 30,
      valid_operations: [:delete],
      operation: nil,
      log_level: Logger::INFO
    }.freeze
  end
end

# Re-open the registry module to add CommandLineSupport module
module Registry
  # Support for command line arguments
  module CommandLineSupport
    # Options parser
    class Options
      attr_reader :parser, :options

      def initialize
        @parser = OptionParser.new
        @options = ::Registry::Config::DEFAULTS.dup
        define_options
      end

      def define_options
        @parser.banner = "Usage: #{$PROGRAM_NAME} [options]"
        define_dry_run_option
        define_path_option
        define_key_option
        define_project_option
        define_interval_option
        define_operation_option
        define_verbose_option
        define_tail
      end

      def define_dry_run_option
        description = 'Show what would have been done; default: yes'
        @parser.on('-d', '--dry-run=[yes/no]', description) do |dry_run|
          @options[:dry_run] = !dry_run.match?(/^(no|false)$/i)
        end
      end

      def define_path_option
        @parser.on('-p', '--path=<path>', 'The path of the registry directory') do |path|
          @options[:path] = path
        end
      end

      def define_key_option
        @parser.on('-k', '--key=<file_path>', 'Path to a GCS key file') do |file_path|
          @options[:key_file_path] = file_path
        end
      end

      def define_project_option
        @parser.on('-P', '--project=<project>', 'The GCS project') do |project|
          @options[:project] = project
        end
      end

      def define_interval_option
        @parser.on('-a', '--age=<age>', Integer, 'File age in days') do |age|
          @options[:age] = age
        end
      end

      def define_operation_option
        @parser.on('-O', '--operation=<delete|...>', 'Operation to invoke on each result') do |arg|
          op = arg.to_sym
          unless Config::DEFAULTS[:valid_operations].include?(op)
            message = "Invalid argument given for --operation: Not a valid operation: #{op}"
            raise OptionParser::InvalidArgument(message)
          end

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
           OptionParser::MissingArgument => e
      puts e.message
      puts opt.parser
      exit
    rescue OptionParser::AmbiguousOption => e
      abort e.message
    end
  end
end

# Re-open the registry module to add Storage class
module Registry
  # Implement filter/selector methods here
  module SelectorMethods
    def filter_by_age(created_at_no_later_than = (DateTime.now - options[:age]))
      files.each do |file|
        yield file if file.created_at < created_at_no_later_than
      end
    end
  end

  # Storage class
  class Storage
    include ::Registry::LoggingSupport
    include ::Registry::SelectorMethods
    attr_reader :options, :project, :client, :buckets_cache, :files_cache
    def initialize(opts)
      @options = opts
      @project = @options[:project]
      @key_file_path = File.expand_path(@options[:key_file_path])
      @buckets_cache = {}
      @files_cache = {}
    end

    def google_cloud_storage_client
      @client ||= Google::Cloud::Storage.new(project_id: @project, credentials: @key_file_path)
    end

    def bucket(bucket_name = @options[:bucket])
      buckets_cache.fetch(bucket_name) do
        buckets_cache[bucket_name] = google_cloud_storage_client.bucket(bucket_name)
      end
    end

    def files(path = @options[:path])
      files_cache.fetch(path) do
        files_cache[path] = bucket.files(prefix: path)
      end
    end

    def safely_invoke_operation(file, operation = options[:operation])
      return if operation.nil? || !file.respond_to?(operation)

      if options[:dry_run]
        log.info "[Dry-run] Would have invoked #{operation} on #{file.name}"
      else
        log.info "Invoking #{operation} on #{file.name}"
        file.method(operation).call
      end
    end
  end
end

# Re-open the registry module to add SearchScript module
module Registry
  # Script module
  module SearchScript
    include ::Registry::LoggingSupport
    include ::Registry::CommandLineSupport

    def main(args = parse(ARGV))
      log.level = args[:log_level]
      dry_run_notice if args[:dry_run]
      storage = Registry::Storage.new(args)
      storage.filter_by_age do |file|
        log.info JSON.pretty_generate(name: file.name, created_at: file.created_at)
        storage.safely_invoke_operation(file)
      end
    rescue SystemExit
      exit
    rescue Interrupt => e
      $stdout.write "\r\n#{e.class}\n"
      $stdout.flush
      exit 0
    end
  end
end

Object.new.extend(Registry::SearchScript).main if $PROGRAM_NAME == __FILE__

#! /usr/bin/env ruby
# frozen_string_literal: true

# Execution:
#
#    sudo su - root
#    mkdir -p /var/opt/gitlab/scripts
#    cd /var/opt/gitlab/scripts
#    curl --silent --remote-name https://gitlab.com/gitlab-com/runbooks/raw/master/scripts/storage_revert.rb
#    chmod +x storage_revert.rb
#
# Staging examples:
#
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_revert.rb --verbose --dry-run=yes --staging --original-file-server=nfs-file09 --project=1234567
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_revert.rb --verbose --dry-run=yes --staging --original-file-server=nfs-file01 --project=1234567
#
# Production examples:
#
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_revert.rb --verbose --dry-run=yes --list-nodes
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_revert.rb --verbose --dry-run=yes --original-file-server=nfs-file33 --project=1234567
#

require 'logger'
require 'optparse'

begin
  require '/opt/gitlab/embedded/service/gitlab-rails/config/environment.rb'
rescue LoadError => e
  warn "WARNING: #{e.message}"
end

# Storage module
module Storage
  DEFAULT_NODE_CONFIG = {}.freeze

  def self.get_node_configuration
    return ::Gitlab.config.repositories.storages.dup if defined? ::Gitlab

    DEFAULT_NODE_CONFIG
  end

  def self.node_configuration
    @node_configuration ||= get_node_configuration
  end
end

# Re-open Storage module to add Logging module
module Storage
  # This module defines logging methods
  module Logging
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
  end
end

# Re-open the Storage module to define the Configuration defaults
module Storage
  # Configuration defaults
  module Config
    DEFAULTS = {
      dry_run: true,
      log_level: Logger::INFO,
      env: :production
    }.freeze
  end
end

# Re-open the Storage module to define the CommandLineSuppport module
module Storage
  # Support for command line arguments
  module CommandLineSupport
    # Options parser
    class Options
      attr_reader :parser, :options

      def initialize
        @parser = OptionParser.new
        @options = ::Storage::Config::DEFAULTS.dup
        define_options
      end

      def define_options
        @parser.banner = "Usage: #{$PROGRAM_NAME} [options]"
        define_dry_run_option
        define_node_option
        define_project_option
        define_list_nodes_option
        define_env_option
        define_verbose_option
        define_tail
      end

      def define_dry_run_option
        description = 'Show what would have been done; default: yes'
        @parser.on('-d', '--dry-run=[yes/no]', description) do |dry_run|
          @options[:dry_run] = !dry_run.match?(/^(no|false)$/i)
        end
      end

      def define_node_option
        description = 'Original storage node server'
        @parser.on_head('--original-file-server=<SERVERNAME>', String, description) do |server|
          @options[:original_file_server] = server
        end
      end

      def define_project_option
        @parser.on_head('--project=<PROJECT_ID>', Integer, 'Project id') do |project_id|
          @options[:project_id] = project_id
        end
      end

      def define_list_nodes_option
        @parser.on('--list-nodes', 'List all known repository storage nodes') do |list_nodes|
          @options[:list_nodes] = true
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

    def parse(args)
      opt = Options.new
      args.push('-?') if args.empty?
      opt.parser.parse!(opt.parser.order!(args) {})
      opt.options
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
      puts e.message
      puts opt.parser
      exit
    rescue OptionParser::AmbiguousOption => e
      abort e.message
    end
  end
  # CommandLineSupport module
end

module Storage
  class Reverter
    include ::Storage::Logging
    def initialize(options)
      @options = options
      log.level = @options[:log_level]
    end

    def list_nodes
      ::Storage.node_configuration.sort.each do |repository_storage_node, node_config|
        gitaly_address = node_config['gitaly_address']
        log.info "#{repository_storage_node}: #{gitaly_address}"
      end
    end

    def revert
      project = Project.find_by(id: @options[:project_id])
      log.info "Project id: #{project.id}"
      log.info "Current repository storage: #{project.repository_storage}"
      if @options[:dry_run]
        log.info "[Dry-run] Would have set repository_storage field of project " \
          "id: #{project.id} to #{@options[:original_file_server]}"
      else
        project.repository_storage = @options[:original_file_server]
        project.repository_read_only = false
        project.save
        log.info "Reverted repository_storage field of project id: #{project.id} " \
          "to #{project.repository_storage}"
      end
    end
  end
end

# Re-open the registry module to add RevertScript module
module Storage
  # RevertScript module
  module RevertScript
    include ::Storage::Logging
    include ::Storage::CommandLineSupport

    def main
      args = parse(ARGV)
      dry_run_notice if args[:dry_run]

      reverter = ::Storage::Reverter.new(args)
      if args[:list_nodes]
        reverter.list_nodes
        exit
      end
      reverter.revert
    rescue SystemExit
      exit 0
    rescue Interrupt => e
      $stdout.write "\r\n#{e.class}\n"
      $stdout.flush
      $stdin.echo = true
      exit 0
    end
  end
end

Object.new.extend(::Storage::RevertScript).main if $PROGRAM_NAME == __FILE__

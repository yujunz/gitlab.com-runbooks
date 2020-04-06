#! /usr/bin/env ruby
# frozen_string_literal: true

# vi: set ft=ruby :

# -*- mode: ruby -*-

require 'json'
require 'logger'
require 'optparse'

# Storage module
module Storage
  # VerifierScript module
  module VerifierScript
    LOG_TIMESTAMP_FORMAT = '%Y-%m-%d %H:%M:%S'
  end
end

# Re-open the Storage module to add the Logging module
module Storage
  # This module defines logging methods
  module Logging
    def initialize_log
      STDOUT.sync = true
      timestamp_format = ::Storage::VerifierScript::LOG_TIMESTAMP_FORMAT
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
  end
end

# Re-open the Storage module to add the Config module
module Storage
  # VerifierScript module
  module VerifierScript
    # Config module
    module Config
      DEFAULTS = {
        log_level: Logger::INFO,
        list: false,
        env: :production,
        logdir_path: '/var/log/gitlab/storage_migrations',
        migration_logfile_name: 'migrated_projects_%{date}.log'
      }.freeze
    end
  end
end

# Support for command line arguments
module CommandLineSupport
  # Options parser
  class Options
    attr_reader :parser, :options

    def initialize
      @parser = OptionParser.new
      @options = Config::DEFAULTS.dup
      define_options
    end

    def define_options
      @parser.banner = "Usage: #{$PROGRAM_NAME} [options]"
      define_list_option
      define_env_option
      define_verbose_option
      define_tail
    end

    def define_list_option
      description = 'List every repository marked as moved'
      @parser.on('-L', '--list-only', description) do
        @options[:list] = true
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

# Re-open the Storage module to define the Verifier class
module Storage
  # The Verifier class
  class Verifier
    include ::Storage::Logging
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

# Re-open the registry module to add VerifierScript module
module Storage
  # VerifierScript module
  module VerifierScript
    include ::Storage::Logging
    include ::Storage::CommandLineSupport

    def main(args = parse(ARGV, ARGF))
      verifier = ::Storage::Verifier.new(args)
      verifier.verify
    end
  end
  # VerifierScript module
end
# Storage module

# Anonymous object avoids namespace pollution
Object.new.extend(::Storage::VerifierScript).main if $PROGRAM_NAME == __FILE__

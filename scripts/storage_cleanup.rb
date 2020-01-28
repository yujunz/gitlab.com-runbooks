#! /usr/bin/env ruby
# frozen_string_literal: true

# vi: set ft=ruby :

# -*- mode: ruby -*-

# This script is a helper for cleaning up projects marked as `moved` on source
# storage node systems.
#
# This script is intended to be invoked from your local workstation system.
#
# Because this script's functionality is destructive in nature,
# it is recommended that one make a manual snapshot of the storage node disk,
# per the instructions found in the Sharding runbook:
# https://gitlab.com/gitlab-com/runbooks/blob/master/howto/sharding.md#how-to-use-it
# Like so:
#
#    gcloud auth login
#    gcloud config set project gitlab-production
#    gcloud config set compute/region us-east1
#    gcloud config set compute/zone us-east1-c
#    gcloud compute disks list | grep file-24-stor-gprd-data
#    gcloud compute disks snapshot file-24-stor-gprd-data
#
# Execution:
#
#    git clone git@gitlab.com:gitlab-com/runbooks.git
#    cd runbooks
#    chmod +x scripts/storage_cleanup.rb
#
# Staging example:
#
#    scripts/storage_cleanup.rb --verbose --dry-run=yes --staging
#
# Production example:
#
#    scripts/storage_cleanup.rb --verbose --dry-run=yes \
#      --node=file-24-stor-gprd.c.gitlab-production.internal --scan --list-only
#    scripts/storage_cleanup.rb --verbose --dry-run=yes \
#      --node=file-24-stor-gprd.c.gitlab-production.internal
#    scripts/storage_cleanup.rb --verbose --dry-run=no \
#      --node=file-24-stor-gprd.c.gitlab-production.internal
#    scripts/storage_cleanup.rb --verbose --dry-run=no \
#      --node=file-24-stor-gprd.c.gitlab-production.internal --scan
#
# This script may be executed on a console node, where the migration log
# records are persisted.  In this case, reading the log files directly
# from the file system is simple enough.
#
# Alternatively, this script could also get executed from the local
# workstation system of an operator.  The migration log files will have
# to get transferred from the console node to the local system.

require 'fileutils'
require 'json'
require 'logger'
require 'optparse'

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
    log.info '[Dry-run] This is only a dry-run -- write operations will be logged but not executed'
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

# Configuration defaults
module Config
  DEFAULTS = {
    dry_run: true,
    log_level: Logger::INFO,
    env: :production,
    storage_root: '/var/opt/gitlab/git-data/repositories',
    hashed_storage_root: '/var/opt/gitlab/git-data/repositories/@hashed',
    logdir_path: '/var/log/gitlab/storage_migrations',
    local_logdir_path: '/tmp/migration_logs',
    type: :logged,
    list: false,
    clean_all: false,
    limit: Float::INFINITY,
    moved_repository_timestamp_pattern: /\+moved\+([\d]+)\./,
    scanned_repositories_order: :time,
    migration_logfile_name: 'migrated_projects_*.log',
    console_nodes: {
      staging: 'console-01-sv-gstg.c.gitlab-staging-1.internal',
      production: 'console-01-sv-gprd.c.gitlab-production.internal'
    },
    disk_space_command: {
      total: 'df -P /dev/sdb | awk "NR==2 {print \\$2}"',
      used: 'df -P /dev/sdb | awk "NR==2 {print \\$3}"'
    },
    nodes_whitelist: []
  }.freeze
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
      define_dry_run_option
      define_nodes_option
      define_limit_option
      define_list_option
      define_type_option
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

    def define_nodes_option
      description = 'One or more FQDNs of nodes to clean'
      @parser.on('-n', '--node=<hostname>,...', Array, description) do |node_fqdns|
        unless node_fqdns.is_a?(Array)
          raise OptionParser::InvalidArgument, 'Invalid argument given for --node'
        end

        @options[:nodes_whitelist] ||= []
        @options[:nodes_whitelist].concat node_fqdns
      end
    end

    def define_limit_option
      description = 'Limit clean-up to N number of projects'
      @parser.on('-l', '--limit=<N>', Integer, description) do |limit|
        @options[:limit] = limit
      end
    end

    def define_list_option
      description = 'List every repository marked as moved'
      @parser.on('-L', '--list-only', description) do
        @options[:list] = true
      end
    end

    def define_type_option
      description = 'Scan and delete every repository marked as moved'
      @parser.on('-S', '--scan', description) do
        @options[:type] = :scanned
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

# Helper methods
module Helpers
  DENOMINATION_CONVERSIONS = {
    'Bytes': 1024,
    'KB': 1024 * 1024,
    'MB': 1024 * 1024 * 1024,
    'GB': 1024 * 1024 * 1024 * 1024,
    'TB': 1024 * 1024 * 1024 * 1024 * 1024
  }.freeze

  def human_friendly_filesize(bytes)
    DENOMINATION_CONVERSIONS.each_pair do |e, s|
      return [(bytes.to_f / (s / 1024)).round(2), e].join(' ') if bytes < s
    end
  end

  def percentage_of_total_disk_space(size, total_disk_space)
    return 0 if total_disk_space <= 0

    ((size / total_disk_space.to_f) * 100).round(2)
  end

  def parse_timestamp(path, regexp)
    regexp.match(path) { |m| Time.at(m.captures.first.to_i).utc } || UNIX_EPOCH
  end
end

# Remote command methods
module RemoteCommands
  def ssh_command(hostname, remote_command)
    debug_command "ssh #{hostname} '#{remote_command}'"
  end

  def scan_for_moved_projects(hostname)
    remote_command = "sudo find #{@options[:hashed_storage_root]} -type d \
-mindepth 2 -maxdepth 3 -name \"*+moved+*.git\""
    log.info "Scanning #{hostname} for moved repositories..."
    `#{ssh_command(hostname, remote_command)}`.strip.split
  end

  def disk_space(hostname, field)
    command = ssh_command(hostname, @options[:disk_space_command][field])
    disk_space_1024_blocks = 0
    begin
      disk_space_1024_blocks = `#{command}`.strip.to_i
    rescue StandardError => e
      log.error "Failed to get #{field} disk space from #{hostname}: #{e.message}"
    end
    disk_space_1024_blocks * 1024
  end

  def get_log_files(hostname)
    logdir_path = @options[:logdir_path]
    return logdir_path if File.exist? logdir_path

    local_logdir_path = @options[:local_logdir_path]
    FileUtils.mkdir_p local_logdir_path
    rsync_command = "rsync --recursive --checksum \
#{hostname}:#{logdir_path}/ #{local_logdir_path}/"
    debug_lines `#{debug_command(rsync_command)}`.strip.split("\n")
    local_logdir_path
  end

  def get_absolute_paths(hostname, paths)
    project_directory_names = paths.collect { |path| "\"#{File.basename(path)}*\"" }
    query = project_directory_names.join(' -o -name ')
    remote_command = "sudo find #{@options[:hashed_storage_root]} \
-type d -mindepth 2 -maxdepth 3 \\( -name #{query} \\)"
    `#{ssh_command(hostname, remote_command)}`.strip.split "\n"
  end

  def estimate_reclaimed_disk_space(hostname, paths)
    remote_command = 'sudo du -s ' + paths.join(' ')
    results = `#{ssh_command(hostname, remote_command)}`.strip.split "\n"
    results.reduce(0) do |sum, line|
      sum + (line.match(/(\d+)\s+/) { |m| m.captures.first.to_i * 1024 } || 0)
    end
  end

  def delete_projects_from_storage_node(hostname, paths)
    remote_command = 'sudo rm -rf ' + paths.join(' ')
    command = "ssh #{hostname} '#{remote_command}'"
    if @options[:dry_run]
      log.info "[Dry-run] Would have run command: #{command}"
      log.info '[Dry-run] Instead will estimate only'
      print_estimate(hostname, paths)
      return
    end

    print_reclaimed(hostname) do
      debug_lines `#{debug_command(command)}`.strip.split("\n")
    end
  end
end
# module RemoteCommands

# This module namespaces the Logging functionality
module Storage
  UNIX_EPOCH = Time.at(0).utc
  ProjectRepository = Struct.new(:source, :path, :time)

  def get_paths_by_source(projects)
    projects.each_with_object({}) do |project, memo|
      memo[project[:source]] ||= []
      memo[project[:source]] << project[:path]
    end
  end

  def find_all_moved_projects(hostname)
    regexp = @options[:moved_repository_timestamp_pattern]
    order = @options[:scanned_repositories_order]
    scan_for_moved_projects(hostname).map do |path|
      ProjectRepository.new(hostname, path, parse_timestamp(path, regexp))
    end.sort_by(&order)
  end

  def list_all_moved_projects
    nodes_whitelist = @options.fetch(:nodes_whitelist, [])
    nodes_whitelist.each do |node|
      log.info('=' * 72)
      find_all_moved_projects(node).each do |repo|
        log.info "Moved #{repo[:time]}: #{repo[:path]}"
      end
      log.info('=' * 72)
    end
    true
  end

  def extract_moved_repository_records(path)
    File.readlines(path).each do |line|
      line.chomp!
      yield JSON.parse(line, symbolize_names: true)
    end
  end

  def get_migrated_repositories_from_logs(log_file_paths)
    log_file_paths.each_with_object([]) do |path, memo|
      extract_moved_repository_records(path) do |record|
        memo << record
      end
    end
  end

  def print_estimate(hostname, paths)
    estimate = estimate_reclaimed_disk_space(hostname, paths)
    percentage = percentage_of_total_disk_space(estimate, disk_space(hostname, :total))
    log.info "Estimated reclaimed disk space: #{human_friendly_filesize(estimate)} \
(#{percentage}% of total)"
  end

  def print_reclaimed(hostname)
    used_initial = disk_space(hostname, :used)
    yield
    reclaimed = used_initial - disk_space(hostname, :used)
    percentage = percentage_of_total_disk_space(reclaimed, disk_space(hostname, :total))
    log.info "Initial used disk space: #{human_friendly_filesize(used_initial)}"
    log.info "Reclaimed disk space: #{human_friendly_filesize(reclaimed)} \
(#{percentage}% of total)"
  end
end

# Re-open Storage module to define Storage::Cleaner class
module Storage
  # Storage::Cleaner class
  class Cleaner
    include ::Logging
    include ::Helpers
    include ::RemoteCommands
    include ::Storage

    def initialize(options)
      @options = options
      @nodes_whitelist = @options.fetch(:nodes_whitelist, [])
      log.level = @options[:log_level]
      exit list_all_moved_projects if @options[:list]

      cleanup(@options[:type] == :scanned ? scanned : logged)
    end

    def delete_projects(projects)
      get_paths_by_source(projects).each do |source_node, paths|
        absolute_paths = get_absolute_paths(source_node, paths)
        delete_projects_from_storage_node(source_node, absolute_paths)
      end
    end

    def scanned
      @nodes_whitelist.each_with_object([]) do |node, memo|
        memo.concat(find_all_moved_projects(node))
      end
    end

    def logged
      local_logdir_path = get_log_files(@options[:console_nodes][@options[:env]])
      log_file_paths = Dir[File.join(local_logdir_path, @options[:migration_logfile_name])].sort
      get_migrated_repositories_from_logs(log_file_paths).filter do |repo|
        !repo[:dry_run] && (@nodes_whitelist.empty? || @nodes_whitelist.include?(repo[:source]))
      end
    end

    def cleanup(remnant_repositories)
      log.info "Found #{remnant_repositories.length} #{@options[:type]} remnant repositories"
      abort if remnant_repositories.empty?

      if @options[:limit] < Float::INFINITY
        log.info "Limiting repository cleanup to #{@options[:limit]} projects"
        remnant_repositories = remnant_repositories[0..@options[:limit]]
      end

      delete_projects(remnant_repositories)
    end
  end
end

# Script module
module Script
  include ::Logging
  include ::CommandLineSupport

  def main
    args = parse(ARGV)
    dry_run_notice if args[:dry_run]
    Storage::Cleaner.new(args)
  rescue SystemExit
    exit
  rescue Interrupt => e
    $stdout.write "\r\n#{e.class}\n"
    $stdout.flush
    exit 0
  end
end

Object.new.extend(Script).main if $PROGRAM_NAME == __FILE__

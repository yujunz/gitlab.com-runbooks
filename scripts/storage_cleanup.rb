#! /usr/bin/env ruby
# This script is a helper for cleaning up projects marked
# as `moved` on source storage node systems.
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
#    scripts/storage_cleanup.rb --verbose --dry-run=yes --node=file-24-stor-gprd.c.gitlab-production.internal
#    scripts/storage_cleanup.rb --verbose --dry-run=no  --node=file-24-stor-gprd.c.gitlab-production.internal
#

require 'fileutils'
require 'json'
require 'logger'
require 'optparse'

def initialize_log
  STDOUT.sync = true
  log = Logger.new STDOUT
  log.level = Logger::INFO
  log.formatter = proc do |level, t, name, msg|
    "%s %-5s %s\n" % [ t.strftime('%Y-%m-%d %H:%M:%S'), level, msg ]
  end
  log
end

class Object
  def log
    @log ||= initialize_log
  end
end

module Storage

Options = {
  dry_run: true,
  log_level: Logger::INFO,
  env: :production,
  logdir_path: '/var/log/gitlab/storage_migrations',
  local_logdir_path: '/tmp/migration_logs',
  limit: Float::INFINITY,
  migration_logfile_name: 'migrated_projects_*.log',
  console_nodes: {
    staging: 'console-01-sv-gstg.c.gitlab-staging-1.internal',
    production: 'console-01-sv-gprd.c.gitlab-production.internal',
  },
  nodes_whitelist: [],
}

def parse_args
  ARGV << '-?' if ARGV.empty?
  opt = OptionParser.new
  opt.banner = "Usage: #{$PROGRAM_NAME} [options]"

  opt.on('-d', '--dry-run=[yes/no]', 'Show what would have been done; default: yes') do |dry_run|
    Options[:dry_run] = (not dry_run =~ /^(no|false)$/i)
  end

  opt.on('-n', '--node=<hostname>', 'Restrict clean-up to a specific source storage node') do |node|
    Options[:nodes_whitelist] ||= []
    Options[:nodes_whitelist] << node
  end

  opt.on('-l', '--limit=<N>', Integer, 'Limit clean-up to N number of projects; oldest first') do |limit|
    Options[:limit] = limit
  end

  opt.on('--staging', 'Use the staging environment') do |env|
    Options[:env] = :staging
  end

  opt.on('-v', '--verbose', 'Increase logging verbosity') do |verbose|
    Options[:log_level] -= 1
  end
  opt.on_tail('-?', '--help', 'Show this message') do
    puts opt
    exit
  end
  args = opt.order!(ARGV) {}
  begin
    opt.parse!(args)
  rescue OptionParser::InvalidOption => e
    puts opt
    exit
  end
  Options
end

class Cleaner
  include ::Storage
  def initialize
    log.level = Options[:log_level]
  end

  DenominationConversions = {
    'Bytes': 1024,
    'KB': 1024 * 1024,
    'MB': 1024 * 1024 * 1024,
    'GB': 1024 * 1024 * 1024 * 1024,
    'TB': 1024 * 1024 * 1024 * 1024 * 1024
  }

  def human_friendly_filesize(bytes)
    DenominationConversions.each_pair do |e, s|
      return "#{(bytes.to_f / (s / 1024)).round(2)} #{e}" if bytes < s
    end
  end

  def find_all_moved_projects(storage_node)
    command = 'find /var/opt/gitlab/git-data/repositories/@hashed -mindepth 2 -maxdepth 3 -type d -name "*+moved*.git"'
    log.debug "Command: #{command}"
    `ssh #{storage_node} '#{command}'`.strip
  end

  def total_disk_space(hostname)
    remote_command = "df -P /dev/sdb | awk \"NR==2 {print \\$2}\""
    command = "ssh #{hostname} '#{remote_command}'"
    log.debug "Command: #{command}"
    total_disk_space_1024_blocks = 0
    begin
      total_disk_space_1024_blocks = `#{command}`.strip.to_i
    rescue StandardError => e
      log.error "Failed to get total disk space from #{hostname}: #{e.message}"
    end
    total_disk_space_1024_blocks * 1024
  end

  def used_disk_space(hostname)
    remote_command = "df -P /dev/sdb | awk \"NR==2 {print \\$3}\""
    command = "ssh #{hostname} '#{remote_command}'"
    log.debug "Command: #{command}"
    used_disk_space_1024_blocks = 0
    begin
      used_disk_space_1024_blocks = `#{command}`.strip.to_i
    rescue StandardError => e
      log.error "Failed to get used disk space from #{hostname}: #{e.message}"
    end
    used_disk_space_1024_blocks * 1024
  end

  def get_migrated_project_logs(log_file_paths)
    moved_projects_log_entries = []

    for path in log_file_paths
      log.debug "Extracting project migration logs from: #{path}"
      File.readlines(path).each do |line|
        line.chomp!
        log.debug "Found migration log entry: #{line}"
        moved_project = JSON.parse(line, :symbolize_names => true)
        moved_projects_log_entries << moved_project unless moved_project[:dry_run]
      end
    end

    moved_projects_log_entries
  end

  def get_log_files(console_node)
    logdir_path = Options[:logdir_path]
    local_logdir_path = Options[:local_logdir_path]
    FileUtils.mkdir_p local_logdir_path

    rsync_command = "rsync --recursive --checksum #{console_node}:#{logdir_path}/ #{local_logdir_path}/"
    log.debug "Command: #{rsync_command}"
    results = `#{rsync_command}`.strip
    log.debug do
      for result in results.split "\n"
        log.debug results
      end
    end

    local_logdir_path
  end

  def get_migrated_projects_from_logs(log_file_paths, limit = Options[:limit])
    nodes_whitelist = Options.fetch(:nodes_whitelist, [])
    log.debug "White-listed nodes: #{nodes_whitelist}"

    moved_projects = get_migrated_project_logs(log_file_paths)

    source_paths = {}
    total_projects = 0
    for moved_project in moved_projects
      source = moved_project[:source]
      next unless nodes_whitelist.empty? || nodes_whitelist.include?(source)
      path = moved_project[:path]
      source_paths[source] ||= []
      source_paths[source] << path
      total_projects += 1
      break if total_projects >= limit
    end

    source_paths
  end

  def delete_from_storage_node(migrated_projects_remaining_on_source_disk)
    if Options[:limit] < Float::INFINITY
      count = migrated_projects_remaining_on_source_disk.inject(0) { |m,h| m += h.last.length }
      log.info "Limiting project cleanup to #{count} projects"
    end
    for source, paths in migrated_projects_remaining_on_source_disk
      used_pre_cleanup = used_disk_space(source)
      total_disk_space = total_disk_space(source)

      remote_command = "sudo find /var/opt/gitlab/git-data/repositories/@hashed -type d -mindepth 2 -maxdepth 3 \\( "
      project_directory_names = paths.collect { |path| "\"#{File.basename(path)}*\"" }
      query = project_directory_names.join " -o -name "
      remote_command << "-name #{query} \\)"
      remote_cleanup_command = remote_command + " -exec rm -rf {} \\;"
      command = "ssh #{source} '#{remote_cleanup_command}'"

      if Options[:dry_run]
        log.info "[Dry-run] Would have run command: #{command}"
        log.info "[Dry-run] Instead will estimate only"
        remote_estimate_command = remote_command + " -exec du -s {} \\;"
        command = "ssh #{source} '#{remote_estimate_command}'"
      end

      log.debug "Command: #{command}"
      results = `#{command}`.strip.split "\n"

      paths = []
      estimated_reclaimed_total = 0
      for result in results
        result.chomp!
        path = result
        if result =~ /\d+\s+/
          size, path = result.split /\s+/
          estimated_reclaimed_total += (size.to_i * 1024)
        end
        log.info "Found project path: #{path}"
      end

      log.info "Initial used disk space: #{human_friendly_filesize(used_pre_cleanup)}"
      if Options[:dry_run]
        if estimated_reclaimed_total > 0
          percentage = ((estimated_reclaimed_total / total_disk_space.to_f) * 100).round(2)
          log.info "Estimated reclaimed disk space: #{human_friendly_filesize(estimated_reclaimed_total)} (#{percentage}% of total)"
        else
          log.info "Estimated reclaimed disk space: 0 bytes"
        end
      else
        reclaimed = [used_pre_cleanup - used_disk_space(source), 0].max
        percentage = ((reclaimed / total_disk_space.to_f) * 100).round(2)
        log.info "Reclaimed disk space: #{human_friendly_filesize(reclaimed)} (#{percentage}% of total)"
      end
    end
  end

  def cleanup
    environment = Options[:env]
    console_nodes = Options[:console_nodes]
    console_node = console_nodes[environment]

    local_logdir_path = get_log_files(console_node)

    logfile_name = Options[:migration_logfile_name]
    log_file_paths = Dir[File.join(local_logdir_path, logfile_name)].sort

    if log_file_paths.empty?
      abort "No project migration log files found on #{console_node}"
    end

    migrated_projects_remaining_on_source_disk = get_migrated_projects_from_logs(log_file_paths)

    if migrated_projects_remaining_on_source_disk.empty?
      abort "No known projects remaining on source disk"
    end

    delete_from_storage_node(migrated_projects_remaining_on_source_disk)
  end
end # class Cleanup

def main
  args = parse_args
  log.level = args[:log_level]
  log.debug "[Dry-run] This is only a dry-run -- operations will be logged but not executed" if args[:dry_run]

  cleaner = Cleaner.new
  cleaner.cleanup
rescue SystemExit => e
  exit 0
rescue Interrupt => e
  $stdout.write "\r\nInterrupted\n"
  $stdout.flush
  exit 0
end

end # module Storage

Object.new.extend(Storage).main if $PROGRAM_NAME == __FILE__

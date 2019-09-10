#! /usr/bin/env ruby
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
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --verbose --dry-run=yes --wait=10800 --current-file-server=nfs-file01 --target-file-server=nfs-file09 --staging --max-failures=200 --refresh-stats
#
# Production examples:
#
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --verbose --dry-run=yes --wait=10800 --current-file-server=nfs-file25 --target-file-server=nfs-file36
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --verbose --dry-run=no --wait=10800 --move-amount=10 --current-file-server=nfs-file27 --target-file-server=nfs-file38 --skip=9271929
#
# Verify the migration status of previously logged project migrations:
#
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --verify-only
#
# Logs may be reviewed:
#
#    export logd=/var/log/gitlab/storage_migrations; for f in `ls -t ${logd}`; do ls -la ${logd}/$f && cat ${logd}/$f; done
#

require 'date'
require 'fileutils'
require 'json'
require 'io/console'
require 'logger'
require 'optparse'
require 'uri'

def initialize_log
  STDOUT.sync = true
  log = Logger.new(STDOUT, level: Logger::INFO)
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

begin
require '/opt/gitlab/embedded/service/gitlab-rails/config/environment.rb'
rescue LoadError => e
log.warn e.message
end

module Storage

ISO8601_FRACTIONAL_SECONDS_LENGTH = 3

NodeConfiguration = {}
NodeConfiguration.merge! ::Gitlab.config.repositories.storages if defined? ::Gitlab

class NoCommits < StandardError; end

Options = {
  dry_run: true,
  log_level: Logger::INFO,
  api_endpoints: {
    staging: 'https://staging.gitlab.com/api/v4/projects/%{project_id}/repository/commits',
    production: 'https://gitlab.com/api/v4/projects/%{project_id}/repository/commits'
  },
  move_amount: 0,
  timeout: 10,
  max_failures: 3,
  list: false,
  black_list: [],
  refresh_statistics: false,
  stats: [:commit_count, :storage_size, :repository_size],
  group: nil,
  env: :production,
  logdir_path: '/var/log/gitlab/storage_migrations',
  migration_logfile_name: 'migrated_projects_%{date}.log',
}

def resembles_integer?(s)
  (not s.to_s.match(/\A\d+\Z/).nil?)
end

def parse_args
  ARGV << '-?' if ARGV.empty?
  opt = OptionParser.new
  opt.banner = "Usage: #{$PROGRAM_NAME} [options] --current-file-server <servername> --target-file-server <servername>"
  opt.separator ''
  opt.separator 'Options:'

  opt.on_head('--current-file-server=<SERVERNAME>', String, 'Source storage node server') do |server|
    Options[:current_file_server] = server
  end

  opt.on_head('--target-file-server=<SERVERNAME>', String, 'Destination storage node server') do |server|
    Options[:target_file_server] = server
  end

  opt.on('-d', '--dry-run=[yes/no]', 'Show what would have been done; default: yes') do |dry_run|
    Options[:dry_run] = (not dry_run =~ /^(no|false)$/i)
  end

  opt.on('--list-nodes', 'List all known repository storage nodes') do |list_nodes|
    Options[:list_nodes] = true
  end

  opt.on('--skip=<project_id,...>', Array, 'Skip specific project(s)') do |project_identifiers|
    Options[:black_list] ||= []
    if project_identifiers.respond_to? :all? and project_identifiers.all? { |s| resembles_integer? s }
      Options[:black_list].concat project_identifiers.map(&:to_i).delete_if { |i| i <= 0 }
    else
      raise OptionParser::InvalidArgument.new("Argument given for --skip must be a list of one or more integers")
    end
  end

  opt.on('-r', '--refresh-stats', 'Refresh all project statistics; WARNING: ignores --dry-run') do |refresh_statistics|
    Options[:refresh_statistics] = true
  end

  opt.on('-N', '--count', 'How many projects are on current file server') do |count|
    Options[:count] = true
  end

  opt.on('-m', '--move-amount=<N>', Integer, "Gigabytes of repo data to move; default: #{Options[:move_amount]}, or largest single repo if 0") do |move_amount|
    abort 'Size too large' if move_amount > 16_000
    Options[:move_amount] = (move_amount * 1024 * 1024 * 1024)  # Convert given gigabytes to bytes
  end

  opt.on('-w', '--wait=<N>', Integer, "Timeout in seconds for migration completion; default: #{Options[:timeout]}") do |wait|
    Options[:timeout] = wait
  end

  opt.on('-V', '--verify-only', 'Verify that projects have successfully migrated') do |verify_only|
    Options[:verify_only] = true
  end

  opt.on('-f', '--max-failures=<N>', Integer, "Maximum failed migrations; default: #{Options[:max_failures]}") do |failures|
    Options[:max_failures] = failures
  end

  opt.on('--group=<GROUPNAME>', String, 'Filter projects by group') do |group|
    Options[:group] = group
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
  begin
    args = opt.order!(ARGV) {}
    opt.parse!(args)
  rescue OptionParser::InvalidOption => e
    puts opt
    exit
  end
  Options
end

class Rebalancer
  include ::Storage
  def initialize
    log.level = Options[:log_level]
    logfile_path = configure_project_migration_logging

    log.info "Moving projects"
    log.info "From: #{Options[:current_file_server]}"
    log.info "To:   #{Options[:target_file_server]}"
    log.debug "Project migration validation timeout: #{Options[:timeout]} seconds"
    log.debug "Migration log file path: #{logfile_path}"
  end

  def configure_project_migration_logging
    logfile_name = Options[:migration_logfile_name] % {
      date: Time.now.strftime('%Y-%m-%d_%H%M%S')
    }
    logdir_path = Options[:logdir_path]
    FileUtils.mkdir_p logdir_path
    logfile_path = File.join(logdir_path, logfile_name)
    FileUtils.touch logfile_path
    @migration_log = Logger.new(logfile_path, level: Logger::INFO)
    @migration_log.formatter = proc { |level, t, name, msg| "#{msg}\n" }
    logfile_path
  rescue StandardError => e
    log.error "Failed to configure logging: #{e.message}"
    exit
  end

  def largest_denomination(bytes)
    if bytes.to_gb > 0
      "#{bytes.to_gb} GB"
    elsif bytes.to_mb > 0
      "#{bytes.to_mb} MB"
    elsif bytes.to_kb > 0
      "#{bytes.to_kb} KB"
    else
      "#{bytes} Bytes"
    end
  end

  def get_storage_node_hostname(storage_node_name)
    hostname = nil
    url = NodeConfiguration.fetch(storage_node_name, {}).fetch('gitaly_address', nil)
    if url
      uri = URI.parse(url)
      hostname = uri.host
    end
    hostname
  end

  def get_commit_id(project_id)
    endpoints = Options[:api_endpoints]
    environment = Options[:env]
    url = endpoints.include?(environment) ? endpoints[environment] : endpoints[:production]
    abort "No api endpoint url is configured" if url.nil? or url.empty?
    url = url % {project_id: project_id}
    uri = URI(url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    request['Private-Token'] = Options.fetch(:private_token) do
      abort "A private API token is required."
    end

    log.debug "[The following curl command is for external diagnostic purposes only:]"
    log.debug "curl --verbose --silent '#{url}' --header \"Private-Token: ${PRIVATE_TOKEN}\""
    response = http.request(request)

    payload = JSON.parse(response.body)
    log.debug "Response code: #{response.code}"
    if payload.empty?
      log.debug "Response payload: []"
    elsif payload.respond_to? :first
      log.debug "Response payload sample:"
      log.debug JSON.pretty_generate(payload.first)
    else
      log.debug "Response payload:"
      log.debug JSON.pretty_generate(payload)
    end

    commit_id = nil
    if response.code.to_i == 200 and not payload.empty?
      first_commit = payload.first
      commit_id = first_commit['id']
    elsif payload.include? 'message'
      log.error "Error: #{payload['message']}"
    end

    commit_id
  end

  def validate(project)
    start = Time.now.to_i
    i = 0
    timeout = Options[:timeout]
    while project.repository_read_only?
      sleep 1
      project.reload
      print '.'
      i += 1
      print "\n" if i % 80 == 0
      elapsed = Time.now.to_i - start
      if elapsed >= timeout
        print "\n"
        log.warn ""
        log.warn "Timed out up waiting for project id: #{project.id} to move: #{elapsed} seconds"
        break
      end
    end
    print "\n"
    if project.repository_storage == Options[:target_file_server]
      log.info "Success moving project id:#{project.id}"
    else
      log.warn "Project id: #{project.id} still reporting incorrect file server"
    end
  end

  def migrate(project)
    log.info "Migrating project id: #{project.id}"
    log.info "  Size: ~#{largest_denomination(project.statistics.repository_size)}"
    log.debug "  Name: #{project.name}"
    log.debug "  Group: #{project.group.name}" unless project.group.nil?
    log.debug "  Storage: #{project.repository_storage}"
    log.debug "  Path: #{project.disk_path}"
    if Options[:refresh_statistics]
      log.debug "Pre-refresh statistics:"
      for stat in Options[:stats]
        log.debug "  #{stat.capitalize}: #{project.statistics[stat]}"
      end
      project.statistics.refresh!(only: Options[:stats])
      log.debug "Post-refresh statistics:"
    else
      log.debug "Project statistics:"
    end
    for stat in Options[:stats]
      log.debug "  #{stat.capitalize}: #{project.statistics[stat]}"
    end

    commit_id = get_commit_id(project.id)
    raise NoCommits.new("Could not obtain any commits for project id #{project.id}") if commit_id.nil?

    log_artifact = {
      id: project.id,
      path: project.disk_path,
      source: get_storage_node_hostname(project.repository_storage),
      destination: get_storage_node_hostname(Options[:target_file_server]),
    }

    if Options[:dry_run]
      log.info "[Dry-run] Would have moved project id: #{project.id}"
      @migration_log.info log_artifact.merge({dry_run: true}).to_json
    else
      log.info "Scheduling migration for project id: #{project.id} to #{Options[:target_file_server]}"
      project.change_repository_storage(Options[:target_file_server])
      project.save

      validate(project)
      log.debug "Refreshing all statistics for project id: #{project.id}"
      project.statistics.refresh!
      log.info "Migrated project id: #{project.id}"
      log.debug "  Name: #{project.name}"
      log.debug "  Storage: #{project.repository_storage}"
      log.debug "  Path: #{project.disk_path}"
      log.info "Validating project integrity by comparing latest commit " +
        "identifers before and after"
      if commit_id == get_commit_id(project.id)
        log_artifact[:date] = DateTime.now.iso8601(ISO8601_FRACTIONAL_SECONDS_LENGTH)
        @migration_log.info log_artifact.to_json
      else
        log.error "Failed to validate integrity of project id: #{project.id}"
      end
    end
  end

  def self.count
    current_file_server = Options[:current_file_server]
    group = Options[:group]
    namespace_id = nil
    if group and not group.empty?
      namespace_id = Namespace.find_by(path: group) rescue nil
      log.error "Group name '#{group}' not found" if namespace_id.nil?
      abort
    end
    Project.transaction do
      ActiveRecord::Base.connection.execute 'SET statement_timeout = 600000'
      clauses = {
        repository_storage: current_file_server,
        delete_error: nil,
        pending_delete: false,
        project_statistics: {commit_count: 1..Float::INFINITY},
      }
      if namespace_id
        log.info "Filtering projects by group: #{group}"
        clauses.merge!(namespace_id: namespace_id)
      end
      Project
        .joins(:statistics)
        .where(**clauses)
        .size
    end
  end

  def get_project_ids(limit=0)
    current_file_server = Options[:current_file_server]
    group = Options[:group]
    namespace_id = nil
    if group and not group.empty?
      Group.find_by_full_path('gitlab-org')
      namespace_id = Namespace.find_by(path: group) rescue nil
      if namespace_id.nil?
        log.error "Group name '#{group}' not found"
        abort
      end
    end
    # Query all projects on the current file server that have not failed
    # any previous delete operations, sort by size descending,
    # then sort by last activity date ascending in order to select the
    # most idle and largest projects first.
    project_identifiers = []
    Project.transaction do
      ActiveRecord::Base.connection.execute 'SET statement_timeout = 600000'
      clauses = {
        repository_storage: current_file_server,
        delete_error: nil,
        pending_delete: false,
        project_statistics: {commit_count: 1..Float::INFINITY},
      }
      if namespace_id
        log.info "Filtering projects by group: #{group}"
        clauses.merge!(namespace_id: namespace_id)
      end
      query = Project
        .joins(:statistics)
        .where(**clauses)
        .order('project_statistics.repository_size DESC')
        .order('last_activity_at ASC')
      query = query.limit(limit) if limit > 0
      project_identifiers = query.pluck(:id)
    end
    black_list = Options[:black_list]
    unless black_list.empty?
      log.debug "Skipping projects: #{black_list}"
      project_identifiers = project_identifiers - black_list
    end
    project_identifiers
  end

  def move_many_projects(min_amount, project_ids)
    failures = 0
    total = 0
    for project_id in project_ids
      project = Project.find_by(id: project_id)
      begin
        migrate(project)
        total += project.statistics.repository_size
      rescue NoCommits => e
        log.error "Error: #{e}"
        log.warn "Skipping migration"
        failures += 1
      rescue StandardError => e
        log.error "Unexpected error migrating project id #{project.id}: #{e}"
        e.backtrace.each { |t| log.error t }
        failures += 1
      end
      if failures > Options[:max_failures]
        log.error "Failed too many times"
        break
      end
      break if total > min_amount
    end
    total = largest_denomination(total)
    if Options[:dry_run]
      log.info "[Dry-run] Would have processed #{total} of data"
    else
      log.info "Processed #{total} of data"
    end
  end

  def move_one_project
    failures = 0
    project_ids = get_project_ids(limit=Options[:max_failures])
    if project_ids.length == 0
      log.info "No movable projects found on #{Options[:current_file_server]}"
    end
    for project_id in project_ids
      project = Project.find_by(id: project_id)
      begin
        migrate(project)
        break
      rescue NoCommits => e
        log.error "Error: #{e}"
        log.warn "Skipping migration"
        failures += 1
      rescue StandardError => e
        log.error "Unexpected error migrating project id: #{project.id}: #{e}"
        e.backtrace.each { |t| log.error t }
        failures += 1
      end
      if failures >= Options[:max_failures]
        log.error "Failed too many times"
      end
    end
  end

  def rebalance
    move_amount_bytes = Options[:move_amount]
    if move_amount_bytes.zero?
      log.info 'Option --move-amount not specified, will only move 1 project...'
      move_one_project
    else
      log.info "Will move at least #{move_amount_bytes.to_gb} GB worth of data"
      move_many_projects(move_amount_bytes, get_project_ids)
    end
  end

end # class Rebalancer

class Verifier
  include ::Storage

  def get_migrated_project_logs(log_file_paths)
    moved_projects_log_entries = []

    for path in log_file_paths
      log.debug "Extracting project migration logs from: #{path}"
      File.readlines(path).each do |line|
        line.chomp!
        log.debug "Migration log entry: #{line}"
        moved_project = JSON.parse(line, :symbolize_names => true)
        moved_projects_log_entries << moved_project unless moved_project[:dry_run]
      end
    end

    moved_projects_log_entries
  end

  def verify
    logdir_path = Options[:logdir_path]
    logfile_name = Options[:migration_logfile_name] % {date: '*'}
    log_file_paths = Dir[File.join(logdir_path, logfile_name)].sort

    moved_projects = get_migrated_project_logs(log_file_paths)

    project_identifiers = moved_projects.map { |project| project[:id] }
    projects = Project.find(project_identifiers)
    for project in projects
      if project.repository_read_only?
        log.info "The repository for project id #{project.id} is still marked read-only on storage node #{project.repository_storage}"
      else
        log.info "The repository for project id #{project.id} appears to have successfully migrated to #{project.repository_storage}"
      end
    end
    log.info "All logged project repository migrations are accounted for"
  end
end # class Verifier

def password_prompt(prompt='Enter private API token: ')
  begin
    $stdout.write(prompt)
    $stdout.flush
    $stdin.noecho(&:gets).chomp
  ensure
    $stdin.echo = true
    $stdout.write "\r" + (' ' * prompt.length)
    $stdout.ioflush
  end
end

def main
  args = parse_args
  log.level = args[:log_level]
  log.debug "[Dry-run] This is only a dry-run -- operations will be logged but not executed" if args[:dry_run]

  source_storage_node = args[:current_file_server]
  destination_storage_node = args[:target_file_server]

  if Options[:verify_only]
    verifier = Verifier.new
    verifier.verify
    exit
  end
  if args[:list_nodes]
    for repository_storage_node in NodeConfiguration.keys.uniq.sort
      gitaly_address = NodeConfiguration[repository_storage_node]['gitaly_address']
      log.info "#{repository_storage_node}: #{gitaly_address}"
    end
    exit
  end
  if source_storage_node and args[:count]
    log.info "Movable projects stored on #{source_storage_node}: #{Rebalancer.count}"
    exit
  end
  if source_storage_node.nil? or destination_storage_node.nil?
    abort "Missing arguments. Use #{$PROGRAM_NAME} --help to see the list of arguments available"
  end
  if NodeConfiguration[source_storage_node]['gitaly_address'] == NodeConfiguration[destination_storage_node]['gitaly_address']
    abort "Given destination file storage node must not have the same gitaly address as the source"
  end

  private_token = ENV.fetch('PRIVATE_TOKEN', nil)
  if private_token.nil? or private_token.empty?
    log.warn "No PRIVATE_TOKEN variable set in environment"
    private_token = password_prompt
    abort "Cannot proceed without a private API token." if private_token.empty?
  end
  Options.store(:private_token, private_token)

  rebalancer = Rebalancer.new
  rebalancer.rebalance
rescue SystemExit => e
  exit 0
rescue Interrupt => e
  $stdout.write "\r\nInterrupted\n"
  $stdout.flush
  $stdin.echo = true
  exit 0
end

end # module Storage

Object.new.extend(Storage).main if $PROGRAM_NAME == __FILE__

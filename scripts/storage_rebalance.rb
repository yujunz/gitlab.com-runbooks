# Execute via:
# `sudo gitlab-rails runner /<path>/<to>/#{$PROGRAM_NAME}`

require 'optparse'

require '/opt/gitlab/embedded/service/gitlab-rails/config/environment.rb'

$stdout.sync = true

options = {
  dry_run: true,
  move_amount: 0,
  wait: 10
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{$PROGRAM_NAME} [options] --current-file-server <servername> --target-file-server <servername>"
  opts.on('--current-file-server SERVERNAME', String, 'Current file server we want to move stuff off from') do |server|
    options[:current_file_server] = server
  end

  opts.on('--target-file-server SERVERNAME', String, 'Server to move stuff too') do |server|
    options[:target_file_server] = server
  end

  opts.on('-d', '--dry-run true', TrueClass, 'Will show you what we would be doing') do |dry_run|
    options[:dry_run] = dry_run
  end

  opts.on('-m', '--move-amount [N]', Integer, 'Amount in GB worth of repo data to move. If no amount provided, only 1 repo will move') do |move_amount|
    abort 'Size too large' if move_amount > 16000
    options[:move_amount] = move_amount
  end

  opts.on('-w', '--wait 10', Integer, 'Time to wait in seconds while validating the move has been completed.') do |wait|
    options[:wait] = wait
  end

  opts.on('-h', '--help', 'Displays Help') do
    puts opts
    exit
  end
end

class MoveIt
  def initialize(current_file_server, target_file_server, move_amount_gb, dry_run, wait)
    @current_fs = current_file_server
    @target_fs = target_file_server
    @move_amount_bytes = move_amount_gb.gigabytes
    @dry_run = dry_run
    @wait_time = wait

    puts "We're moving things from #{@current_fs} _TO_ #{@target_fs}"
    puts "We'll wait up to #{@wait_time} seconds to validate between project moves"
  end

  def to_gb(input)
    input / 1024 / 1024 / 1024
  end

  def get_commit(project_id)
    uri = URI("https://gitlab.com/api/v4/projects/#{project_id}/repository/commits")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Get.new(uri.request_uri)
    req['Private-Token'] = ENV.fetch('PRIVATE_TOKEN')

    res = http.request(req)

    return nil if res.code.to_i != 200

    jd = JSON.parse(res.body)

    if jd.first
      return jd.first['id'] unless jd.first['id'].empty?
    end

    return nil
  end

  def move_many_projects(min_amount, project_ids)
    size = 0
    while size < min_amount
      project_ids.each do |id|
        project = Project.find(id)
        puts "Project id:#{project.id} is ~#{project.statistics.repository_size.to_gb} GB"
        size += project.statistics.repository_size
        move_project(project)
        if size > min_amount
          puts "Processed #{size.to_gb} GB of data"
          break
        end
      end
    end
  end

  def validate(project)
    i = 0
    while project.repository_read_only?
      sleep 1
      project.reload
      print '.'
      i += 1
      if i == @wait_time
        puts
        puts "\nTimed out up waiting for id:#{project.id} to move"
        break
      end
    end
    puts
    if project.repository_storage != @target_fs
      puts "Project id:#{project.id} still reporting incorrect file server"
    else
      puts "Success moving id:#{project.id}"
    end
  end

  def validate_integrity(project, commit)
    unless commit == get_commit(project.id)
      puts "Failed validating integrity for id:#[project.id}"
    end
  end

  def move_project(project)
    commit = get_commit(project.id)
    if commit.nil?
      puts "Cannot obtain a commit id:#{project.id}, skipping..."
      return
    end

    if @dry_run
      puts "Would move id:#{project.id}"
    else
      print "Scheduling move id:#{project.id} to #{@target_fs}"
      change_result = project.change_repository_storage(@target_fs)
      project.save
      if change_result == nil
        puts "Failed scheduling id:#{project.id}"
      else
        validate(project)
        validate_integrity(project, commit) unless commit.nil?
      end
    end
  end

  def get_project_ids
    # query all projects on the current file server, sort by size descending,
    # then sort by last activity date ascending
    # I want the most idle largest projects
    Project.transaction do
      ActiveRecord::Base.connection.execute 'SET statement_timeout = 600000'
      Project
        .joins(:statistics)
        .where(repository_storage: @current_fs)
        .order('project_statistics.repository_size DESC')
        .order('last_activity_at ASC')
        .pluck(:id)
      ActiveRecord::Base.connection.execute 'SET statement_timeout = 30000'
    end
  end

  def go
    if @move_amount_bytes.zero?
      puts 'Option --move-amount not specified, will only move 1 project...'
      project = Project.find(get_project_ids.first)
      puts "Will move id:#{project.id}"
      move_project(project)
    else
      puts "Will move at least #{@move_amount_bytes.to_gb}GB worth of data"
      move_many_projects(@move_amount_bytes, get_project_ids)
    end
  end
end

parser.parse!

if options[:current_file_server].nil? || options[:target_file_server].nil?
  abort("Missing arguments. Use #{$PROGRAM_NAME} --help to see the list of arguments available")
end

MoveIt.new(options[:current_file_server], options[:target_file_server], options[:move_amount], options[:dry_run], options[:wait]).go

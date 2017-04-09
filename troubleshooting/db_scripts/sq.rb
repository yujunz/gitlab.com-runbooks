#!/usr/bin/env ruby
#
# A sidekick for Sidekiq
#
# A command-line tool for managing Sidekiq jobs and queues.
#
# If you need to run this on a Omnibus GitLab machine, run:
#
# sudo gitlab-rails runner /full_pathname/sq.rb [kill|show|kill_jid] <worker name or Job ID>
#
# Or:
#
# BUNDLE_GEMFILE=/opt/gitlab/embedded/service/gitlab-rails/Gemfile /opt/gitlab/embedded/bin/bundle exec /opt/gitlab/embedded/bin/ruby sq.rb -h <hostname> -a <password> [kill|show|kill_jid] <worker name or Job ID>
#
require 'optparse'
require 'sidekiq/api'

Options = Struct.new(
  :command,
  :dry_run,
  :hostname,
  :password,
  :socket
)

def parse_options(argv)
  options = Options.new

  opt_parser = OptionParser.new do |opt|
    opt.banner = "Usage: #{__FILE__} [options] [kill|show|kill_jid] <worker name or job ID>"

    opt.on('-a', '--auth PASSWORD', 'Redis password') do |password|
      options.password = password
    end

    opt.on('--hostname HOSTNAME', 'Redis hostname') do |hostname|
      options.hostname = hostname
    end

    opt.on('-s', '--socket <UNIX socket>', 'Redis UNIX socket') do |socket|
      options.socket = socket
    end

    opt.on('--dry-run', 'Dry run') do |value|
      options.dry_run = value
    end

    opt.on('-h', '--help', 'Print help message') do
      puts opt
      exit
    end
  end

  opt_parser.parse!(argv)

  # Command is everything that remains
  options.command = argv

  options
end

def configure_sidekiq(options)
  return unless options.socket || options.hostname

  redis_config = { namespace: 'resque:gitlab' }

  redis_config[:url] =
    if options.socket
      "unix://#{options.socket}"
    elsif options.hostname
      "redis://#{options.hostname}"
    else
      'redis://localhost:6379'
    end

  redis_config[:password] = options.password if options.password

  Sidekiq.configure_client do |config|
    config.redis = redis_config
  end
end

def load_sidekiq_queue_data
  queue = Sidekiq::Queue.all
  class_type = Hash.new { |hash, key| hash[key] = 1 }
  class_by_args = Hash.new { |hash, key| hash[key] = 1 }

  queue.each do |q|
    q.each do |job|
      class_type[job.klass] += 1
      class_by_args[[job.klass, job.args]] += 1
    end
  end

  [class_type, class_by_args]
end

def kill_jobs_by_worker_name(options, worker_name)
  queue = Sidekiq::Queue.all
  count = 0

  queue.each do |q|
    q.each do |job|
      next unless job.klass == worker_name

      count += 1
      job.delete unless options.dry_run
    end
  end

  count
end

def kill_job_by_id(options, job_id)
  queue = Sidekiq::Queue.all

  queue.each do |q|
    q.each do |job|
      next unless job.jid == job_id

      job.delete unless options.dry_run
      return true
    end
  end

  false
end

def pretty_print(data)
  data = data.sort_by { |_key, value| value }.reverse

  data.each do |key, value|
    puts "#{key}: #{value}"
  end
end

def show_sidekiq_data
  queue_data, job_data = load_sidekiq_queue_data
  puts '-----------'
  puts 'Queue size:'
  puts '-----------'
  pretty_print(queue_data)
  puts '------------------------------'
  puts 'Top job counts with arguments:'
  puts '------------------------------'
  pretty_print(job_data)
end

if $PROGRAM_NAME == __FILE__
  options = parse_options(ARGV)
  configure_sidekiq(options)

  show_sidekiq_data unless options.command.length > 0

  case options.command[0]
  when 'show'
    show_sidekiq_data
  when 'kill_jid'
    if options.command.length != 2
      puts 'Specify a Job ID to kill'
      exit
    end

    jid = options.command[1]
    result = kill_job_by_id(options, jid)
    if result
      puts "Killed job ID #{jid}"
    else
      puts "Unable to find job ID #{jid}"
    end
  when 'kill'
    if options.command.length != 2
      puts 'Specify a worker (e.g. RepositoryUpdateMirrorWorker)'
      exit
    end

    count = kill_jobs_by_worker_name(options, options.command[1])
    puts "Killed #{count} jobs"
  end
end

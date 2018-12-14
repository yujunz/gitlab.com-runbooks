#!/usr/bin/env /opt/gitlab/embedded/bin/ruby
# frozen_string_literal: true
require 'optparse'
require 'open3'
require 'rainbow/refinement'
require 'httparty'

using Rainbow

options = {}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"
  opts.on('-u', '--username gitlabuser', 'Username') do |user|
    options[:user] = user
  end

  opts.on('-p', '--project full/project/path', 'Project path, such as namespace1/myproject') do |project|
    options[:project] = project
  end

  opts.on('-f', '--file /path/to/export.tar.gz', 'Path to the export archive') do |file|
    options[:file] = file
  end

  opts.on('-h', '--help', 'Displays Help') do
    puts opts

    exit
  end
end

parser.parse!

abort("Missing options. Use #{$0} --help to see the list of options available".red) if options.values.empty?

require '/opt/gitlab/embedded/service/gitlab-rails/config/environment.rb'

class SlackWebhook
  CouldNotPostError = Class.new(StandardError)

  CHANNEL = '#announcements'
  WEBHOOK_URL = 'https://hooks.slack.com/services/' + ENV['SLACK_TOKEN'].to_s

  def self.start(project)
    fire_hook("#{username} started a foreground import of *#{project}*")
  end

  def self.error(project, error)
    fire_hook("#{username} started a foreground import of *#{project}*", attachment: error)
  end

  def self.done(project)
    fire_hook("#{username} finished a foreground import of *#{project}*")
  end
  
  def self.username
    @username ||= `whoami`
  end

  def self.fire_hook(text, attachment: nil, channel: CHANNEL)
    return unless ENV['SLACK_TOKEN']

    body = { text: text }
    body[:channel] = channel
    body[:attachments] = [{ text: attachment, color: 'danger' }] if attachment
    response = HTTParty.post(WEBHOOK_URL, body: body.to_json)

    raise CouldNotPostError, response.inspect unless response.code == 200
  end

  private_class_method :fire_hook
end


class LocalProjectService < ::Projects::CreateService
  IMPORT_JOBS_EXPIRATION = 48.hours.to_i

  def import_schedule
    @project.import_state.update_column(:status, 'scheduled')

    if @project.errors.empty?
      job_id = 'custom-import-@project.id-' + SecureRandom.base64

      @project.import_state.update_column(:jid, job_id) if job_id
      @project.log_import_activity(job_id)

      RepositoryImportWorker.new.perform(@project.id)

      Gitlab::SidekiqStatus.set(job_id, IMPORT_JOBS_EXPIRATION)
    else
      puts @project.errors.full_messages.join(', ').red
      raise(error: @project.errors.full_messages.join(', '))
    end
  end
end

class GitlabProjectImport
  def initialize(project_path, gitlab_username, file_path)
    @project_path = project_path
    @current_user = User.find_by_username(gitlab_username)
    @file_path = file_path
  end

  def import
    show_warning!

    SlackWebhook.start(@project_path)

    import_project

    if @project&.import_state&.last_error
      puts @project.import_state.last_error
      SlackWebhook.error(@project_path, @project.import_state.last_error)
    elsif @project.errors.any?
      puts @project.errors.full_messages.join(', ').red
      SlackWebhook.error(@project_path, @project.errors.full_messages.join(', '))
    else
      puts 'Done!'.green
      SlackWebhook.done(@project_path)
    end
  end

  private

  def show_warning!
    puts "Importing GitLab export: #{@file_path.bold} into GitLab #{@project_path.bold} as #{@current_user.name.bold}"
  end

  def import_project
    namespace_path, _sep, name = @project_path.rpartition('/')
    namespace = Groups::NestedCreateService.new(@current_user, group_path: namespace_path).execute
    upload = ImportExportUpload.new(import_file: File.open(@file_path))

    @project = LocalProjectService.new(@current_user,
                                       namespace_id: namespace.id,
                                       path: name,
                                       import_type: 'gitlab_project',
                                       import_export_upload: upload).execute
  end
end

GitlabProjectImport.new(options[:project], options[:user], options[:file]).import

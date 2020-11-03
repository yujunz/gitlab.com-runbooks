#! /usr/bin/env ruby
# frozen_string_literal: true

# vi: set ft=ruby :

# -*- mode: ruby -*-

# This script must be ran on a console node. It will find all git project
# repositories belonging to blocked users of gitlab.com, and generate a
# json-formatted enumeration of the project identifiers (id field values)
# which will be saved into a file in the /var/opt/gitlab/scripts/artifacts/
# directory.
#
# ssh console-01-sv-gstg.c.gitlab-staging-1.internal
# sudo mkdir -p /var/opt/gitlab/scripts/artifacts
# sudo chgrp git /var/opt/gitlab/scripts/artifacts
# sudo chmod 0775 /var/opt/gitlab/scripts/artifacts
#
# Example invocation:
#
# gitlab-rails runner /var/opt/gitlab/scripts/projects_belonging_to_blocked_users.rb

require 'json'
require 'logger'

begin
  require '/opt/gitlab/embedded/service/gitlab-rails/config/environment.rb'
rescue LoadError => e
  warn "WARNING: #{e.message}"
end

log = Logger.new(STDOUT)
log.level = Logger::INFO
log.formatter = proc do |level, t, _name, msg|
  format("%<timestamp>s %-5<level>s %<msg>s\n", timestamp: t.strftime('%Y-%m-%d %H:%M:%S'), level: level, msg: msg)
end

file_name = 'projects_belonging_to_blocked_users_' + Time.now.strftime('%Y-%m-%d_%H%M%S') + '.json'
output_file_path = File.join(__dir__, 'artifacts', file_name)

blocked_users = User.blocked.all.to_a

projects = []
projects_belonging_to_blocked_users = blocked_users.each_with_object([]) { |user, projects| projects.concat(user.projects) }
total_projects_belonging_to_blocked_users = projects_belonging_to_blocked_users.length
projects.concat(projects_belonging_to_blocked_users)

log.info "Found #{total_projects_belonging_to_blocked_users} projects belonging to blocked users"

data = { projects: projects.map(&:id) }

File.open(output_file_path, 'w') do |f|
  f.write(data.to_json)
end

log.info "Saved projects to: #{output_file_path}"

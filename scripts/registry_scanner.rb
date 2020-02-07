#! /usr/bin/env ruby
# frozen_string_literal: true

# This script helps identify the cause of "invalid checksum digest
# format" and "unexpected end of JSON" error messages due to 0-byte
# files. It assumes you have access to the gitlab-gprd-registry bucket
# vs gsutil.  Given a "/manifests" URL that is returning a 500 error:
#
# 1. Look up the tag and the associated current file.
# 2. Scan the revisions path for the sha256/<blob>.
# 3. Scan the blob path (gs://gitlab-gprd-registry/docker/registry/v2/blobs/sha256/:sha[0..1]/:sha)
#
# If there are any 0-byte files in the list, this script will display
# the gsutil commands to remove them.

require 'English'

class RegistryScanner
  ZeroByteFileError = Class.new(StandardError)

  def initialize(path)
    parse_path(path)
  end

  def check
    check_tag
    check_revision
    check_blob
  rescue ZeroByteFileError => e
    puts e
    show_removal_instructions
  rescue RuntimeError => e
    puts e
  end

  private

  def parse_path(path)
    path =~ %r{/v2/(.*)/manifests/(.*)}

    @registry_path = Regexp.last_match(1)
    @sha = Regexp.last_match(2)
  end

  def base_path
    'gs://gitlab-gprd-registry/docker/registry/v2'
  end

  def manifest_path
    "#{base_path}/repositories/#{@registry_path}/_manifests/tags/#{@sha}"
  end

  def current_manifest
    "#{manifest_path}/current/link"
  end

  def revision_path
    "#{base_path}/repositories/#{@registry_path}/_manifests/revisions/sha256/#{@revision}"
  end

  def revision_link
    "#{revision_path}/link"
  end

  def blob_data
    "#{base_path}/blobs/sha256/#{@blob_sha[0..1]}/#{@blob_sha}/data"
  end

  def show_removal_instructions
    puts ''
    puts 'To remove these file(s), you may want to run:'
    puts '================================================'
    puts "gsutil rm #{blob_data}" if @blob_sha
    puts "gsutil rm -r #{revision_path}" if @revision
    puts "gsutil rm -r #{manifest_path}" if @sha
    puts '================================================'
  end

  def check_tag
    puts "Checking tag #{@sha}..."
    @revision = read_sha256(current_manifest)
  end

  def check_revision
    puts "Checking revision #{@revision}"
    @blob_sha = read_sha256(revision_link)
  end

  def check_blob
    puts "Checking blob #{@blob_sha}..."
    read_sha256(blob_data)
  end

  def read_sha256(filename)
    current = `gsutil cat #{filename}`

    raise "Error reading: #{filename}" unless $CHILD_STATUS.success?
    raise ZeroByteFileError, "0-byte file found: #{filename}" if current.length.zero?

    current.gsub!(/^sha256:/, '')
  end
end

if ARGV.length != 1 || !ARGV[0].include?('/manifests/')
  puts 'Syntax: registry_scanner.rb <bad manifest URL>'
  puts ''
  puts 'Example: registry_scanner.rb /v2/namespace/project/my-registry/manifests/latest'
  exit
end

path = ARGV[0]
scanner = RegistryScanner.new(path)
scanner.check

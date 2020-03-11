# frozen_string_literal: true

require 'spec_helper'

require_relative '../scripts/storage_rebalance.rb'

unless defined? Project
  # Define a dummy Project class
  class Project
  end
end

describe ::Storage::Rebalancer do
  subject { described_class.new(options) }
  let(:test_node_01) { 'nfs-file03' }
  let(:test_node_02) { 'nfs-file04' }
  let(:gitaly_address_fqdn_01) { 'test.01' }
  let(:gitaly_address_fqdn_02) { 'test.02' }
  let(:gitaly_address_01) { "test://#{gitaly_address_fqdn_01}" }
  let(:gitaly_address_02) { "test://#{gitaly_address_fqdn_02}" }
  let(:node_configuration) do
    { test_node_01 => { 'gitaly_address' => gitaly_address_01 },
      test_node_02 => { 'gitaly_address' => gitaly_address_02 } }
  end
  let(:test_private_token) { 'test_token' }
  let(:test_project_id) { 1 }
  let(:dry_run) { true }
  let(:args) do
    { current_file_server: test_node_01, target_file_server: test_node_02,
      project_id: test_project_id, dry_run: dry_run, private_token: test_private_token }
  end
  let(:defaults) { ::Storage::RebalanceScript::Config::DEFAULTS.dup.merge(args) }
  let(:options) { defaults }

  before do
    allow(::Storage).to receive(:node_configuration).and_return(node_configuration)
  end

  describe '#print_node_list' do
    it 'prints a list of the configured storage shard nodes' do
      expect(subject.log).to receive(:info).with("#{test_node_01}: #{gitaly_address_01}")
      expect(subject.log).to receive(:info).with("#{test_node_02}: #{gitaly_address_02}")
      expect(subject.print_node_list).to eq(
        [
          [test_node_01, { 'gitaly_address' => gitaly_address_01 }],
          [test_node_02, { 'gitaly_address' => gitaly_address_02 }]
        ]
      )
    end
  end

  describe '#rebalance' do
    let(:test_repository_size) { 1 * 1024 * 1024 * 1024 }
    let(:test_project_commit_count) { 1 }
    let(:largest_denomination) { '1 GB' }
    let(:statistics) do
      statistics = double('ProjectStatistics')
      allow(statistics).to receive(:repository_size).and_return(test_repository_size)
      allow(statistics).to receive(:[]).with(:repository_size).and_return(test_repository_size)
      allow(statistics).to receive(:[]).with(:storage_size).and_return(test_repository_size)
      allow(statistics).to receive(:[]).with(:commit_count).and_return(test_project_commit_count)
      statistics
    end
    let(:test_project_name) { 'test/test_project_name' }
    let(:test_project_group_name) { 'test_project_group' }
    let(:test_project_group) do
      group = double('group')
      allow(group).to receive(:name).and_return(test_project_group_name)
      group
    end
    let(:test_project_disk_path) { 'test/project_disk_path' }
    let(:test_repository) do
      repository = double('Repository')
      allow(repository).to receive(:expire_exists_cache)
      repository
    end
    let(:test_project) do
      project = double('project')
      allow(project).to receive(:id).and_return(test_project_id)
      allow(project).to receive(:name).and_return(test_project_name)
      allow(project).to receive(:group).and_return(test_project_group)
      allow(project).to receive(:disk_path).and_return(test_project_disk_path)
      allow(project).to receive(:repository_storage).and_return(test_node_01)
      allow(project).to receive(:statistics).and_return(statistics)
      allow(project).to receive(:repository).and_return(test_repository)
      project
    end
    let(:test_updated_project) do
      project = double('updated_project')
      allow(project).to receive(:id).and_return(test_project_id)
      allow(project).to receive(:name).and_return(test_project_name)
      allow(project).to receive(:group).and_return(test_project_group)
      allow(project).to receive(:disk_path).and_return(test_project_disk_path)
      allow(project).to receive(:repository_storage).and_return(test_node_02)
      allow(project).to receive(:statistics).and_return(statistics)
      allow(project).to receive(:repository).and_return(test_repository)
      project
    end
    let(:test_commit_id) { 1 }
    let(:test_commit) { { id: test_commit_id } }
    let(:test_commits) { [test_commit] }
    let(:response_body) { test_commits.to_json }
    let(:response_code) { 200 }
    let(:response) do
      response = double('Net::HTTP::Response')
      allow(response).to receive(:body).and_return(response_body)
      allow(response).to receive(:code).and_return(response_code)
      response
    end
    let(:net_http) do
      net_http = double('Net::HTTP::Request')
      allow(net_http).to receive(:use_ssl=).with(true)
      allow(net_http).to receive(:request).with(net_http_get_request).and_return(response)
      net_http
    end
    let(:net_http_get_request) do
      net_http_get_request = double('Net::HTTP::Get')
      allow(net_http_get_request).to receive(:[]=).with('Private-Token', test_private_token)
      net_http_get_request
    end
    let(:test_migration_logger) { double('FileLogger') }
    let(:test_artifact) do
      artifact = {
        id: test_project_id,
        path: test_project_disk_path,
        source: gitaly_address_fqdn_01,
        destination: gitaly_address_fqdn_02
      }
      artifact[:dry_run] = dry_run if dry_run == true
      artifact[:date] = test_time if defined? test_time
      artifact
    end

    before do
      allow(subject).to receive(:init_project_migration_logging).and_return(test_migration_logger)
      allow(Net::HTTP).to receive(:new).and_return(net_http)
      allow(Net::HTTP::Get).to receive(:new).and_return(net_http_get_request)
    end

    context 'when the --dry-run option is true' do
      it 'logs the rebalance operation' do
        project = test_project
        allow(subject).to receive(:get_project_ids).and_return([test_project_id])
        allow(subject).to receive(:largest_denomination).and_return(largest_denomination)
        allow(Project).to receive(:find_by).with(id: test_project_id).and_return(project)
        expect(subject.log).to receive(:info)
          .with('Option --move-amount not specified, will only move 1 project...')
        expect(subject.log).to receive(:info).with('Moving 1 projects')
        expect(subject.log).to receive(:info).with("From: #{test_node_01}")
        expect(subject.log).to receive(:info).with("To:   #{test_node_02}")
        expect(subject.log).to receive(:info).with('=' * 72)
        expect(subject.log).to receive(:info).with("Migrating project id: #{test_project_id}")
        expect(subject.log).to receive(:info).with("  Size: ~#{largest_denomination}")
        expect(subject.log).to receive(:info)
          .with("[Dry-run] Would have processed #{largest_denomination} of data")
        expect(subject.log).to receive(:info)
          .with("[Dry-run] Would have moved project id: #{test_project_id}")
        expect(test_migration_logger).to receive(:info).with(test_artifact.to_json)
        expect(subject.log).to receive(:info).with('=' * 72)
        expect(subject.log).to receive(:info)
          .with("Finished migrating projects from #{test_node_01} to #{test_node_02}")
        expect(subject.log).to receive(:info).with("No errors encountered during migration")
        expect(subject.rebalance).to be_nil
      end
    end

    context 'when the --dry-run option is false' do
      let(:dry_run) { false }
      let(:test_time) do
        DateTime.now.iso8601(::Storage::Helpers::ISO8601_FRACTIONAL_SECONDS_LENGTH)
      end
      let(:test_datetime) do
        datetime = double('DateTime')
        allow(datetime).to receive(:iso8601)
          .with(::Storage::Helpers::ISO8601_FRACTIONAL_SECONDS_LENGTH)
          .and_return(test_time)
        datetime
      end
      let(:curl_command) do
        "curl --verbose --silent 'https://gitlab.com/api/v4/projects/#{test_project_id}/" \
          "repository/commits' --header \"Private-Token: ${PRIVATE_TOKEN}\""
      end

      it 'performs the rebalance operation' do
        project = test_project
        allow(subject).to receive(:get_project_ids).and_return([test_project_id])
        allow(subject).to receive(:largest_denomination).and_return('1 GB')
        allow(Project).to receive(:find_by).with(id: test_project_id).and_return(project, test_updated_project)
        expect(subject.log).to receive(:info)
          .with('Option --move-amount not specified, will only move 1 project...')
        expect(subject.log).to receive(:info).with('Moving 1 projects')
        expect(subject.log).to receive(:info).with("From: #{test_node_01}")
        expect(subject.log).to receive(:info).with("To:   #{test_node_02}")
        expect(subject.log).to receive(:info).with('=' * 72)
        expect(subject.log).to receive(:info).with("Migrating project id: #{test_project_id}")
        expect(subject.log).to receive(:info).with("  Size: ~#{largest_denomination}")
        expect(subject.log).to receive(:debug)
          .with("Project migration validation timeout: 10800 seconds")
        expect(subject.log).to receive(:debug).with("  Name: #{test_project_name}")
        expect(subject.log).to receive(:debug).with("  Group: #{test_project_group_name}")
        expect(subject.log).to receive(:debug).with("  Storage: #{test_node_01}")
        expect(subject.log).to receive(:debug).with("  Path: #{test_project_disk_path}")
        expect(subject.log).to receive(:debug).with('Project statistics:')
        expect(subject.log).to receive(:debug).with("  commit_count: #{test_commits.length}")
        expect(subject.log).to receive(:debug).with("  storage_size: #{test_repository_size}")
        expect(subject.log).to receive(:debug).with("  repository_size: #{test_repository_size}")
        expect(subject.log).to receive(:debug)
          .with("[The following curl command is for external diagnostic purposes only:]")
        expect(subject.log).to receive(:debug).with(curl_command)
        expect(subject.log).to receive(:debug).with("Response code: #{response_code}")
        expect(subject.log).to receive(:debug).with("Response payload sample: {\n  \"id\": #{test_project_id}\n}")
        expect(subject.log).to receive(:debug).with("Total commits: #{test_commits.length}")
        expect(subject.log).to receive(:debug).with("Refreshing all statistics for project id: 1")
        expect(subject.log).to receive(:debug).with("Original commit id: 1, current commit id: 1")
        expect(subject.log).to receive(:debug).with("  Storage: #{test_node_02}")
        expect(subject.log).to receive(:debug).with("  Name: #{test_project_name}")
        expect(subject.log).to receive(:debug).with("  Path: #{test_project_disk_path}")
        expect(subject.log).to receive(:debug)
          .with("[The following curl command is for external diagnostic purposes only:]")
        expect(subject.log).to receive(:debug).with(curl_command)
        expect(subject.log).to receive(:debug).with("Response code: #{response_code}")
        expect(subject.log).to receive(:debug).with("Response payload sample: {\n  \"id\": #{test_project_id}\n}")
        expect(subject.log).to receive(:debug).with("Total commits: #{test_commits.length}")
        expect(subject.log).to receive(:info)
          .with("Scheduling migration for project id: #{test_project_id} to #{test_node_02}")
        expect(project).to receive(:change_repository_storage).with(test_node_02)
        expect(project).to receive(:save)
        expect(test_migration_logger).to receive(:info).with(test_artifact.to_json)
        allow(project).to receive(:repository_read_only?).and_return(true)
        allow(project).to receive(:reload)
        expect(subject).to receive(:wait_for_repository_storage_update).with(project)
        expect(statistics).to receive(:refresh!)
        log_message = 'Validating project integrity by comparing latest commit identifiers ' \
          'before and after'
        expect(subject.log).to receive(:info).with(log_message)
        expect(subject.log).to receive(:info).with("Migrated project id: #{test_project_id}")
        allow(DateTime).to receive(:now).and_return(test_datetime)
        expect(subject.log).to receive(:info).with("Processed #{largest_denomination} of data")
        expect(subject.log).to receive(:info).with('=' * 72)
        expect(subject.log).to receive(:info).with("Finished migrating projects from #{test_node_01} to " \
          "#{test_node_02}")
        expect(subject.log).to receive(:info).with("No errors encountered during migration")
        expect(subject.rebalance).to be_nil
      end
    end
  end
end

describe ::Storage::RebalanceScript do
  subject { Object.new.extend(::Storage::RebalanceScript) }
  let(:test_node_01) { 'nfs-file03' }
  let(:test_node_02) { 'nfs-file04' }
  let(:gitaly_address_01) { 'test://test.01' }
  let(:gitaly_address_02) { 'test://test.02' }
  let(:node_configuration) do
    { test_node_01 => { 'gitaly_address' => gitaly_address_01 },
      test_node_02 => { 'gitaly_address' => gitaly_address_02 } }
  end
  let(:dry_run) { true }
  let(:args) do
    { current_file_server: test_node_01, target_file_server: test_node_02,
      project_id: 1, dry_run: dry_run }
  end
  let(:defaults) { ::Storage::RebalanceScript::Config::DEFAULTS.dup.merge(args) }
  let(:options) { defaults }
  let(:rebalancer) { double('::Registry::Rebalancer') }

  before do
    allow(::Storage).to receive(:node_configuration).and_return(node_configuration)
    ENV['PRIVATE_TOKEN'] = 'test'
    allow(rebalancer).to receive(:options).and_return(options)
  end

  describe '#main' do
    context 'when the dry-run option is true' do
      it 'logs the given operation' do
        expect(subject).to receive(:parse).and_return(options)
        expect(::Storage::Rebalancer).to receive(:new).and_return(rebalancer)
        expect(rebalancer).to receive(:rebalance)
        expect(subject.log).to receive(:info).with('[Dry-run] This is only a dry-run -- write ' \
          'operations will be logged but not executed')
        expect(subject.main).to be_nil
      end
    end

    context 'when the dry-run option is false' do
      let(:options) { defaults.merge(dry_run: false) }

      it 'safely invokes the given operation' do
        expect(subject).to receive(:parse).and_return(options)
        expect(::Storage::Rebalancer).to receive(:new).and_return(rebalancer)
        expect(rebalancer).to receive(:rebalance)
        expect(subject.log).not_to receive(:info)
        expect(subject.main).to be_nil
      end
    end
  end
end

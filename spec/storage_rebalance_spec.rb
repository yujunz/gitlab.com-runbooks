# frozen_string_literal: true

require 'spec_helper'

require_relative '../scripts/storage_rebalance.rb'

describe ::Storage::Rebalancer do
  subject { described_class.new(options) }
  let(:test_node_01) { 'nfs-file03' }
  let(:test_node_02) { 'nfs-file04' }
  let(:test_private_token) { 'test_token' }
  let(:test_commit_id) { 1 }
  let(:test_project_id) { 1 }
  let(:dry_run) { true }
  let(:args) do
    { source_shard: test_node_01, destination_shard: test_node_02,
      dry_run: dry_run }
  end
  let(:defaults) { ::Storage::RebalanceScript::Config::DEFAULTS.dup.merge(args) }
  let(:options) { defaults }
  let(:projects) { [{ id: test_project_id }] }

  describe '#rebalance' do
    let(:projects) { [test_project] }
    let(:test_repository_size) { 1 * 1024 * 1024 * 1024 }
    let(:test_project_commit_count) { 1 }
    let(:largest_denomination) { '1 GB' }
    let(:gitaly_address_fqdn_01) { 'test.01' }
    let(:gitaly_address_fqdn_02) { 'test.02' }
    let(:gitaly_address_01) { "test://#{gitaly_address_fqdn_01}" }
    let(:gitaly_address_02) { "test://#{gitaly_address_fqdn_02}" }
    let(:node_configuration) do
      { test_node_01 => { 'gitaly_address' => gitaly_address_01 },
        test_node_02 => { 'gitaly_address' => gitaly_address_02 } }
    end
    let(:test_project_name) { 'test_project_name' }
    let(:test_project_path_with_namespace) { 'test/test_project_name' }
    let(:test_project_disk_path) { 'test/project_disk_path' }
    let(:test_repository) do
      repository = double('Repository')
      allow(repository).to receive(:expire_exists_cache)
      repository
    end
    let(:test_project) do
      {
        id: test_project_id,
        name: test_project_name,
        path_with_namespace: test_project_path_with_namespace,
        disk_path: test_project_disk_path,
        statistics: {
          repository_size: test_repository_size
        },
        repository_storage: test_node_01,
        destination_repository_storage: test_node_02
      }
    end
    let(:test_project_json) { test_project.to_json }
    let(:test_projects) { { projects: [test_project] } }
    let(:test_projects_json) { test_projects.to_json }
    let(:test_full_project) do
      { id: test_project_id, name: test_project_name, path_with_namespace: test_project_path_with_namespace,
        disk_path: test_project_disk_path, repository_storage: test_node_01 }
    end
    let(:test_project_put_response) { { 'id': test_project_id }.transform_keys(&:to_s) }
    let(:test_updated_full_project) do
      { id: test_project_id, name: test_project_name, path_with_namespace: test_project_path_with_namespace,
        disk_path: test_project_disk_path, repository_storage: test_node_02 }
    end
    let(:test_moves) { [{ 'project': { 'id': test_project_id }, 'state': 'finished' }] }
    let(:test_move) { { 'project': { 'id': test_project_id }, 'state': 'started' } }
    let(:test_migration_logger) { double('FileLogger') }
    let(:test_time) { DateTime.now.iso8601(::Storage::Helpers::ISO8601_FRACTIONAL_SECONDS_LENGTH) }
    let(:test_artifact) do
      {
        id: test_project_id,
        path: test_project_disk_path,
        # size: test_repository_size,
        source: test_node_01,
        destination: test_node_02,
        date: test_time
      }
    end
    let(:test_migration_failure_id) { 1234567890 }
    let(:test_migration_failures) do
      [
        {
          project_id: test_migration_failure_id,
          message: "Noticed service failure during repository replication",
          disk_path: "@hashed/12/34/1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqr",
          source: test_node_01,
          destination: test_node_02,
          date: test_time
        }
      ]
    end
    let(:test_hostname) { options[:console_nodes][:production] }
    let(:test_command) do
      "sudo gitlab-rails runner /var/opt/gitlab/scripts/storage_project_selector.rb " \
        "#{test_node_01} #{test_node_02} --limit=1 --skip=#{test_migration_failure_id}"
    end
    let(:options) do
      defaults.merge(
        source_shard: test_node_01,
        destination_shard: test_node_02,
        dry_run: dry_run
      )
    end

    before do
      allow(subject).to receive(:init_project_migration_logging).and_return(test_migration_logger)
      allow(subject).to receive(:options).and_return(options)
      allow(subject).to receive(:get_commit_id).and_return(test_commit_id)
      allow(subject).to receive(:fetch_repository_storage_moves).and_return(test_moves)
      allow(subject).to receive(:load_migration_failures).and_return(test_migration_failures)
      allow_any_instance_of(DateTime).to receive(:iso8601)
        .with(::Storage::Helpers::ISO8601_FRACTIONAL_SECONDS_LENGTH)
        .and_return(test_time)
    end

    context 'when the --dry-run option is true' do
      before do
        allow(subject).to receive(:fetch_project).and_return(test_project)
        allow(subject).to receive(:fetch_largest_projects).and_return([test_project])
      end

      it 'logs the rebalance operation' do
        # allow(subject).to receive(:paginate_projects).and_yield(test_project)

        expect(subject.log).to receive(:info).with(
          'Option --move-amount not specified, will only move 1 project...')
        expect(subject.log).to receive(:info).with('Fetching largest projects')
        expect(subject.log).to receive(:info).with("Filtering #{test_migration_failures.length} " \
          "known failed project repositories")
        expect(subject.log).to receive(:info).with(::Storage::RebalanceScript::SEPARATOR)
        expect(subject.log).to receive(:info).with("Scheduling repository replication to " \
          "#{test_node_02} for project id: #{test_project_id}")
        expect(subject.log).to receive(:info).with("  Project path: #{test_project_path_with_namespace}")
        expect(subject.log).to receive(:info).with("  Current shard name: #{test_node_01}")
        expect(subject.log).to receive(:info).with("  Disk path: #{test_project_disk_path}")
        expect(subject.log).to receive(:info).with("  Repository size: 1.0 GB")
        expect(subject.log).to receive(:info).with("[Dry-run] Would have scheduled repository " \
          "replication for project id: #{test_project_id}")
        expect(subject.log).to receive(:info).with(::Storage::RebalanceScript::SEPARATOR)
        expect(subject.log).to receive(:info).with('[Dry-run] Would have processed 1.0 GB of data')
        expect(subject.log).to receive(:info).with('Done')
        expect(subject.rebalance).to be_nil
      end
      # it 'logs the rebalance operation'

      context 'when the projects are not given' do
        it 'selects the projects from the configured console node' do
          expect(subject.log).to receive(:info)
            .with('Option --move-amount not specified, will only move 1 project...')
          expect(subject.log).to receive(:info).with('Fetching largest projects')
          expect(subject.log).to receive(:info).with("Filtering #{test_migration_failures.length} " \
            "known failed project repositories")
          expect(subject.log).to receive(:info).with(::Storage::RebalanceScript::SEPARATOR)
          expect(subject.log).to receive(:info).with("Scheduling repository replication to " \
            "#{test_node_02} for project id: #{test_project_id}")
          expect(subject.log).to receive(:info).with("  Project path: #{test_project_path_with_namespace}")
          expect(subject.log).to receive(:info).with("  Current shard name: #{test_node_01}")
          expect(subject.log).to receive(:info).with("  Disk path: #{test_project_disk_path}")
          expect(subject.log).to receive(:info).with("  Repository size: 1.0 GB")
          expect(subject.log).to receive(:info).with("[Dry-run] Would have scheduled repository " \
            "replication for project id: #{test_project_id}")
          expect(subject.log).to receive(:info).with(::Storage::RebalanceScript::SEPARATOR)
          expect(subject.log).to receive(:info).with('[Dry-run] Would have processed 1.0 GB of data')
          expect(subject.log).to receive(:info).with('Done')
          expect(subject.rebalance).to be_nil
        end
        # it 'selects the projects from the configured console node'
      end
      # context 'when the projects are not given'
    end
    # context 'when the --dry-run option is true'

    context 'when the --dry-run option is false' do
      let(:dry_run) { false }

      before do
        allow(subject).to receive(:fetch_project).and_return(test_project)
        allow(subject).to receive(:fetch_largest_projects).and_return([test_project])
      end

      it 'logs the rebalance operation' do
        # allow(subject).to receive(:paginate_projects).and_yield(test_project)
        allow(subject).to receive(:create_repository_storage_move).and_return(test_move)
        allow(subject).to receive(:fetch_repository_storage_move).and_return(test_move)

        expect(subject.log).to receive(:info)
          .with('Option --move-amount not specified, will only move 1 project...')
        expect(subject.log).to receive(:info).with('Fetching largest projects')
        expect(subject.log).to receive(:info).with("Filtering #{test_migration_failures.length} " \
          "known failed project repositories")
        expect(subject.log).to receive(:info).with(::Storage::RebalanceScript::SEPARATOR)
        expect(subject.log).to receive(:info).with("Scheduling repository replication to " \
          "#{test_node_02} for project id: #{test_project_id}")
        expect(subject.log).to receive(:info).with("  Project path: #{test_project_path_with_namespace}")
        expect(subject.log).to receive(:info).with("  Current shard name: #{test_node_01}")
        expect(subject.log).to receive(:info).with("  Disk path: #{test_project_disk_path}")
        expect(subject.log).to receive(:info).with("  Repository size: 1.0 GB")
        expect(subject).to receive(:loop_with_progress_until).and_yield.and_yield
        expect(subject).to receive(:fetch_project).and_return(test_full_project)
        expect(subject).to receive(:fetch_project).and_return(test_updated_full_project)
        expect(subject).to receive(:fetch_repository_storage_moves).and_return(test_moves)
        expect(subject.log).to receive(:info).with("Success moving project id: #{test_project_id}")
        expect(test_migration_logger).to receive(:info).with(test_artifact.to_json)
        expect(subject.log).to receive(:info).with("Migrated project id: #{test_project_id}")
        expect(subject.log).to receive(:info).with(::Storage::RebalanceScript::SEPARATOR)
        expect(subject.log).to receive(:info).with('Done')
        expect(subject.log).to receive(:info).with('Processed 1.0 GB of data')
        expect(subject.log).to receive(:info).with("Finished migrating projects from #{test_node_01} to #{test_node_02}")
        expect(subject.log).to receive(:info).with('No errors encountered during migration')
        expect(subject.rebalance).to be_nil
      end
      # it 'logs the rebalance operation'

      context 'when the projects are not given' do
        it 'selects the projects from the configured console node' do
          allow(subject).to receive(:create_repository_storage_move).and_return(test_move)
          allow(subject).to receive(:fetch_repository_storage_move).and_return(test_move)

          expect(subject.log).to receive(:info)
            .with('Option --move-amount not specified, will only move 1 project...')
          expect(subject.log).to receive(:info).with('Fetching largest projects')
          expect(subject.log).to receive(:info).with("Filtering #{test_migration_failures.length} " \
            "known failed project repositories")
          expect(subject.log).to receive(:info).with(::Storage::RebalanceScript::SEPARATOR)
          expect(subject.log).to receive(:info).with("Scheduling repository replication to " \
            "#{test_node_02} for project id: #{test_project_id}")
          expect(subject.log).to receive(:info).with("  Project path: #{test_project_path_with_namespace}")
          expect(subject.log).to receive(:info).with("  Current shard name: #{test_node_01}")
          expect(subject.log).to receive(:info).with("  Disk path: #{test_project_disk_path}")
          expect(subject.log).to receive(:info).with("  Repository size: 1.0 GB")
          expect(subject).to receive(:create_repository_storage_move).with(test_project, test_node_02).and_return(test_move)
          expect(subject).to receive(:loop_with_progress_until).and_yield.and_yield
          expect(subject).to receive(:fetch_project).and_return(test_full_project)
          allow(subject).to receive(:fetch_repository_storage_moves).and_return(test_moves)
          allow(subject).to receive(:fetch_repository_storage_moves).and_return(test_moves)
          expect(subject.log).to receive(:info).with("Success moving project id: #{test_project_id}")
          expect(subject).to receive(:fetch_project).and_return(test_updated_full_project)
          expect(test_migration_logger).to receive(:info).with(test_artifact.to_json)
          expect(subject.log).to receive(:info).with("Migrated project id: #{test_project_id}")
          expect(subject.log).to receive(:info).with(::Storage::RebalanceScript::SEPARATOR)
          expect(subject.log).to receive(:info).with('Done')
          expect(subject.log).to receive(:info).with('Processed 1.0 GB of data')
          expect(subject.log).to receive(:info).with("Finished migrating projects from #{test_node_01} to #{test_node_02}")
          expect(subject.log).to receive(:info).with('No errors encountered during migration')
          expect(subject.rebalance).to be_nil
        end
        # it 'selects the projects from the configured console node'
      end
      # context 'when the projects are not given'
    end
    # context 'when the --dry-run option is false'
  end
  # describe '#rebalance'
end
# describe ::Storage::Rebalancer

describe ::Storage::RebalanceScript do
  subject { Object.new.extend(::Storage::RebalanceScript) }
  let(:test_project_id) { 1 }
  let(:test_node_01) { 'nfs-file03' }
  let(:test_node_02) { 'nfs-file04' }
  let(:dry_run) { true }
  let(:args) do
    { source_shard: test_node_01, destination_shard: test_node_02,
      projects: projects, dry_run: dry_run }
  end
  let(:defaults) { ::Storage::RebalanceScript::Config::DEFAULTS.dup.merge(args) }
  let(:options) { defaults }
  let(:rebalancer) { double('::Storage::Rebalancer') }
  let(:projects) { [{ id: test_project_id }] }
  let(:test_token) { 'test' }
  let(:no_token_message) { 'Cannot proceed without a GitLab admin API private token' }

  before do
    allow(::Storage::Rebalancer).to receive(:new).and_return(rebalancer)
    allow(rebalancer).to receive(:set_api_token_or_else)
    allow(subject).to receive(:parse).and_return(options)
    token_env_variable_name = options[:token_env_variable_name]
    allow(ENV).to receive(:[]).with(token_env_variable_name).and_return(test_token)
  end

  describe '#main' do
    context 'when no token is provided' do
      let(:test_token) { nil }

      it 'aborts and whines about it' do
        expect(subject.log).to receive(:info).with('[Dry-run] This is only a dry-run -- write ' \
          'operations will be logged but not executed')
        expect(rebalancer).to receive(:set_api_token_or_else).and_yield
        expect { subject.main }.to raise_error(SystemExit, no_token_message).and output(Regexp.new(no_token_message)).to_stderr
      end
      # it 'aborts and whines about it'
    end
    # context 'when no token is provided'

    context 'when the dry-run option is true' do
      it 'logs the given operation' do
        expect(subject.log).to receive(:info).with('[Dry-run] This is only a dry-run -- write ' \
          'operations will be logged but not executed')
        expect(rebalancer).to receive(:rebalance)
        expect(subject.main).to be_nil
      end
      # it 'logs the given operation'
    end
    # context 'when the dry-run option is true'

    context 'when the dry-run option is false' do
      let(:options) { defaults.merge(dry_run: false) }

      it 'safely invokes the given operation' do
        expect(subject).to receive(:parse).and_return(options)
        expect(rebalancer).to receive(:rebalance)
        expect(subject.log).not_to receive(:info)
        expect(subject.main).to be_nil
      end
      # it 'safely invokes the given operation'
    end
    # context 'when the dry-run option is false'
  end
  # describe '#main'
end
# describe ::Storage::RebalanceScript

describe ::Storage::GitLabClient do
  subject { described_class.new(options) }
  let(:defaults) { ::Storage::RebalanceScript::Config::DEFAULTS.dup }
  let(:options) { defaults.merge({ gitlab_admin_api_token: test_token }) }
  let(:test_token) { 'test' }

  let(:test_request) { double('Net::HTTPRequest') }

  let(:test_status_code) { test_response_code_ok }
  let(:test_response_code_ok) { 200 }
  let(:test_response_body) do
    body = {}
    body['resource'] = 'value'
    body
  end
  let(:test_response_headers) { {} }
  let(:test_response_body_serialized_json) { test_response_body.to_json }
  let(:test_error) { nil }
  let(:test_response_successful) do
    response = double('Net::HTTP::Response')
    allow(response).to receive(:code).and_return(test_response_code_ok)
    allow(response).to receive(:body).and_return(test_response_body_serialized_json)
    allow(response).to receive(:each_header)
    response
  end
  let(:test_response_code_not_found) { 404 }
  let(:test_not_found_message) { 'NotFound' }
  let(:test_http_not_found_error) { Net::HTTPClientException.new(test_not_found_message, test_response_not_found) }
  let(:test_response_not_found) do
    response = double('Net::HTTP::Response')
    allow(response).to receive(:code).and_return(test_response_code_not_found)
    allow(response).to receive(:body).and_return(test_response_body_serialized_json)
    response
  end

  let(:test_headers) { ['test: header'] }
  let(:net_http) do
    net_http = double('Net::HTTP')
    allow(net_http).to receive(:use_ssl=).with(true)
    net_http
  end
  let(:get_url) { 'https://test.com/api/resource.json' }
  let(:put_url) { 'https://test.com/api/resource.json' }
  let(:post_url) { 'https://test.com/api/resource.json' }

  RSpec::Matchers.define :an_http_request do |x|
    match { |actual| actual.is_a?(Net::HTTPRequest) }
  end

  before do
    allow(subject).to receive(:execute).with(net_http, an_http_request).and_return([test_response, test_status_code])
    allow(Net::HTTP).to receive(:new).and_return(net_http)
  end

  context 'when GET https://test.com/api/resource.json' do
    let(:test_method) { Net::HTTP::Get }
    let(:test_response) { test_response_successful }

    it 'returns the deserialized resource with no error and status code 200' do
      expect(subject.get(get_url)).to eq([test_response_body, test_error, test_status_code, test_response_headers])
    end

    context 'when the requested resource does not exist' do
      let(:test_response) { test_response_not_found }
      let(:test_status_code) { test_response_code_not_found }
      let(:test_response_body) { {} }
      let(:test_error) { test_http_not_found_error }

      it 'returns an empty hash with the error and status code 404' do
        expect(subject).to receive(:execute).and_raise(test_http_not_found_error)
        expect(subject.log).to receive(:error).with(test_not_found_message)
        expect(subject.get(get_url)).to eq([test_response_body, test_error, test_status_code, test_response_headers])
      end
      # it 'returns an empty hash with the error and status code 404'
    end
    # context 'when the requested resource does not exist'
  end
  # context 'when GET https://test.com/api/resource.json'

  context 'when PUT https://test.com/api/resource.json' do
    let(:test_method) { Net::HTTP::Put }
    let(:test_response) { test_response_successful }

    it 'returns the deserialized resource with no error and status code 200' do
      expect(subject.put(put_url)).to eq([test_response_body, nil, 200, test_response_headers])
    end

    context 'when the requested resource does not exist' do
      let(:test_response) { test_response_not_found }
      let(:test_status_code) { test_response_code_not_found }
      let(:test_response_body) { {} }
      let(:test_error) { test_http_not_found_error }

      it 'returns an empty hash with the error and status code 404' do
        expect(subject).to receive(:execute).and_raise(test_http_not_found_error)
        expect(subject.log).to receive(:error).with(test_not_found_message)
        expect(subject.get(get_url)).to eq([test_response_body, test_error, test_status_code, test_response_headers])
      end
      # it 'returns an empty hash with the error and status code 404'
    end
    # context 'when the requested resource does not exist'
  end
  # context 'when PUT https://test.com/api/resource.json'

  context 'when POST https://test.com/api/resource.json' do
    let(:test_method) { Net::HTTP::Post }
    let(:test_response) { test_response_successful }

    it 'returns the deserialized resource with no error and status code 200' do
      expect(subject.post(post_url)).to eq([test_response_body, nil, 200, test_response_headers])
    end

    context 'when the requested resource does not exist' do
      let(:test_response) { test_response_not_found }
      let(:test_status_code) { test_response_code_not_found }
      let(:test_response_body) { {} }
      let(:test_error) { test_http_not_found_error }

      it 'returns an empty hash with the error and status code 404' do
        expect(subject).to receive(:execute).and_raise(test_http_not_found_error)
        expect(subject.log).to receive(:error).with(test_not_found_message)
        expect(subject.get(get_url)).to eq([test_response_body, test_error, test_status_code, test_response_headers])
      end
      # it 'returns an empty hash with the error and status code 404'
    end
    # context 'when the requested resource does not exist'
  end
  # context 'when POST https://test.com/api/resource.json'
end
# describe ::Storage::GitLabClient

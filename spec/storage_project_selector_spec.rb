# frozen_string_literal: true

require 'spec_helper'

require_relative '../scripts/storage_project_selector.rb'

unless defined? Project
  # Define a dummy Project class
  class Project
  end
end

describe ::Storage::ProjectSelector do
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
  let(:shard_entry_01) do
    entry = {}
    entry['repository_storage'] = test_node_01
    entry['gitaly_address'] = gitaly_address_01
    entry
  end
  let(:shard_entry_02) do
    entry = {}
    entry['repository_storage'] = test_node_02
    entry['gitaly_address'] = gitaly_address_02
    entry
  end
  let(:test_time) { DateTime.now.iso8601(::Storage::Helpers::ISO8601_FRACTIONAL_SECONDS_LENGTH) }
  let(:test_output) do
    test_output = {}
    test_output['shards'] = [shard_entry_01, shard_entry_02]
    test_output['timestamp'] = test_time
    test_output
  end
  let(:test_node_configuration_json) { JSON.pretty_generate(test_output) }
  let(:test_private_token) { 'test_token' }
  let(:test_project_id) { 1 }
  let(:args) { { source_shard: test_node_01, destination_shard: test_node_02 } }
  let(:defaults) { ::Storage::ProjectSelectorScript::Config::DEFAULTS.dup.merge(args) }
  let(:options) { defaults }
  let(:test_projects) { [{ id: test_project_id }] }

  before do
    allow(::Storage).to receive(:node_configuration).and_return(node_configuration)
    allow_any_instance_of(DateTime).to receive(:iso8601)
      .with(::Storage::Helpers::ISO8601_FRACTIONAL_SECONDS_LENGTH)
      .and_return(test_time)
  end

  describe '#print_configured_gitaly_shards' do
    it 'prints a list of the configured storage shard nodes' do
      expect { subject.print_configured_gitaly_shards }.to output(test_node_configuration_json + "\n").to_stdout
    end
  end

  describe '#get_projects' do
    it 'executes the project selection sql query and returns the adapted results' do
      allow(Project).to receive(:joins).with(id: test_project_id).and_return(test_projects)
    end
  end
end

describe ::Storage::ProjectSelectorScript do
  subject { Object.new.extend(::Storage::ProjectSelectorScript) }
  let(:test_node_01) { 'nfs-file03' }
  let(:test_node_02) { 'nfs-file04' }
  let(:gitaly_address_01) { 'test://test.01' }
  let(:gitaly_address_02) { 'test://test.02' }
  let(:node_configuration) do
    { test_node_01 => { 'gitaly_address' => gitaly_address_01 },
      test_node_02 => { 'gitaly_address' => gitaly_address_02 } }
  end
  let(:args) { { source_shard: test_node_01, destination_shard: test_node_02 } }
  let(:defaults) { ::Storage::ProjectSelectorScript::Config::DEFAULTS.dup.merge(args) }
  let(:options) { defaults }
  let(:project_selector) { double('::Registry::ProjectSelector') }
  let(:test_project_id) { 1 }
  let(:test_projects) { [{ id: test_project_id }] }
  let(:test_time) { DateTime.now.iso8601(::Storage::Helpers::ISO8601_FRACTIONAL_SECONDS_LENGTH) }
  let(:test_output) do
    test_output = {}
    test_output['projects'] = test_projects
    test_output['timestamp'] = test_time
    test_output
  end
  let(:test_projects_json) { JSON.pretty_generate(test_output) }

  before do
    allow(::Storage).to receive(:node_configuration).and_return(node_configuration)
    allow(project_selector).to receive(:options).and_return(options)
    allow_any_instance_of(DateTime).to receive(:iso8601)
      .with(::Storage::Helpers::ISO8601_FRACTIONAL_SECONDS_LENGTH)
      .and_return(test_time)
  end

  describe '#main' do
    it 'prints a list of projects with adapted details' do
      expect(subject).to receive(:parse).and_return(options)
      expect(::Storage::ProjectSelector).to receive(:new).and_return(project_selector)
      expect(project_selector).to receive(:get_projects).and_return(test_projects)
      expect { subject.main }.to output(test_projects_json + "\n").to_stdout
    end
  end
end

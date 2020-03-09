# frozen_string_literal: true

require 'spec_helper'

require_relative '../scripts/storage_revert.rb'

unless defined? Project
  # Define a dummy Project class
  class Project
  end
end

describe ::Storage::Reverter do
  subject { described_class.new(options) }
  let(:test_project_id) { 1 }
  let(:dry_run) { true }
  let(:node_name) { 'nfs-file03' }
  let(:gitaly_address) { 'test://test' }
  let(:node_configuration) { { node_name => { 'gitaly_address' => gitaly_address } } }
  let(:args) { { original_file_server: node_name, project_id: test_project_id, dry_run: dry_run } }
  let(:defaults) { ::Storage::RevertScript::Config::DEFAULTS.dup.merge(args) }
  let(:options) { defaults }

  describe '#list_nodes' do
    it 'prints a list of the configured storage shard nodes' do
      allow(::Storage).to receive(:node_configuration).and_return(node_configuration)
      expect(subject.log).to receive(:info).with("#{node_name}: #{gitaly_address}")
      expect(subject.list_nodes).to eq([[node_name, { 'gitaly_address' => gitaly_address }]])
    end
  end

  describe '#revert' do
    let(:test_project) do
      project = double('project')
      allow(project).to receive(:id).and_return(test_project_id)
      allow(project).to receive(:repository_storage).and_return('test')
      project
    end

    context 'when the --dry-run option is true' do
      it 'logs the revert operation' do
        project = test_project
        allow(Project).to receive(:find_by).with(id: test_project_id).and_return(project)
        expect(subject.log).to receive(:info).with("Project id: #{test_project_id}")
        expect(subject.log).to receive(:info).with("Current repository " \
          "storage: test")
        expect(subject.log).to receive(:info).with("[Dry-run] Would have set repository_storage " \
          "field of project id: #{test_project_id} to nfs-file03")
        expect(subject.revert).to be_nil
      end
    end

    context 'when the --dry-run option is false' do
      let(:dry_run) { false }

      it 'performs the revert operation' do
        expect(subject).not_to receive(:node_configuration)
        project = test_project
        expect(project).to receive(:repository_storage=).with('nfs-file03')
        expect(project).to receive(:repository_read_only=).with(false)
        expect(project).to receive(:save)
        allow(Project).to receive(:find_by).with(id: test_project_id).and_return(project)
        expect(subject.log).to receive(:info).with("Project id: #{test_project_id}")
        expect(subject.log).to receive(:info).with("Current repository " \
          "storage: test")
        expect(subject.log).to receive(:info).with("Reverted repository_storage field of " \
          "project id: #{test_project_id} to test")
        expect(subject.revert).to be_nil
      end
    end
  end
end

describe ::Storage::RevertScript do
  subject { Object.new.extend(::Storage::RevertScript) }
  let(:dry_run) { true }
  let(:node_configuration) { { 'nfs-file03': 'test://test' } }
  let(:args) { { original_file_server: 'nfs-file03', project_id: 1, dry_run: dry_run } }
  let(:defaults) { ::Storage::RevertScript::Config::DEFAULTS.dup.merge(args) }
  let(:options) { defaults }
  let(:reverter) { double('::Registry::Reverter') }

  describe '#main' do
    context 'when the dry-run option is true' do
      it 'logs the given operation' do
        expect(subject).to receive(:parse).and_return(options)
        expect(::Storage::Reverter).to receive(:new).and_return(reverter)
        expect(reverter).to receive(:revert)
        expect(subject.log).to receive(:info).with("[Dry-run] This is only a dry-run -- write operations will be logged but not executed")
        expect(subject.main).to be_nil
      end
    end

    context 'when the dry-run option is false' do
      let(:options) { defaults.merge(dry_run: false) }

      it 'safely invokes the given operation' do
        expect(subject).to receive(:parse).and_return(options)
        expect(::Storage::Reverter).to receive(:new).and_return(reverter)
        expect(reverter).to receive(:revert)
        expect(subject.log).not_to receive(:info)
        expect(subject.main).to be_nil
      end
    end
  end
end

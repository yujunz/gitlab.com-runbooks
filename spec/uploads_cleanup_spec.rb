# frozen_string_literal: true

require 'spec_helper'

require_relative '../scripts/uploads_cleanup.rb'

describe ::Uploads::Cleaner do
  subject { described_class.new(options) }
  let(:host) { options[:hostname] }
  let(:disk_path) { 'test/path' }
  let(:file) { 'test' }
  let(:operation) { :delete }
  let(:args) { { disk_path: disk_path, operation: operation } }
  let(:defaults) { ::Uploads::CleanupScript::Config::DEFAULTS.dup.merge(args) }
  let(:options) { defaults }

  describe '#safely_invoke_operation' do
    let(:path) { File.join(options[:uploads_dir_path], disk_path) }
    let(:found) { File.join(path, 'tmp/test') }
    let(:find_command) do
      format(
        options[:remote_command],
        hostname: options[:hostname],
        command: format(options[:find], path: path)
      )
    end

    context 'when the dry-run option is true' do
      it 'logs a dry-run informational message' do
        expect(subject).to receive(:invoke).with(find_command).and_return(found)
        expect(subject).to receive(:options).at_least(1).times.and_return(options)
        expect(subject.log).to receive(:info)
          .with("[Dry-run] Would have invoked command: ssh #{host} 'sudo rm -rf #{found}'")
        expect(subject.clean).to eq([found])
      end
    end

    context 'when the dry-run option is false' do
      let(:options) { defaults.merge(dry_run: false) }
      let(:delete_command) do
        format(
          options[:remote_command],
          hostname: options[:hostname],
          command: format(options[:delete], path: found)
        )
      end

      it 'logs the operation and executes it' do
        allow(subject).to receive(:invoke).with(find_command).and_return(found)
        expect(subject).to receive(:options).at_least(1).times.and_return(options)
        expect(subject.log).to receive(:info)
          .with("Invoking command: ssh #{host} 'sudo rm -rf #{found}'")
        expect(subject).to receive(:invoke).with(delete_command).and_return('')
        expect(subject.clean).to eq([found])
      end
    end
  end
end

describe ::Uploads::CleanupScript do
  subject { Object.new.extend(::Uploads::CleanupScript) }
  let(:args) { { operation: :delete } }
  let(:defaults) { ::Uploads::CleanupScript::Config::DEFAULTS.dup.merge(args) }
  let(:options) { defaults }
  let(:cleanup) { double('::Uploads::Cleaner') }

  before do
    allow(subject).to receive(:parse).and_return(options)
  end

  describe '#main' do
    context 'when the dry-run option is true' do
      it 'logs the given operation' do
        expect(::Uploads::Cleaner).to receive(:new).and_return(cleanup)
        expect(cleanup).to receive(:clean)
        expect(subject.log).to receive(:info).with("[Dry-run] This is only a dry-run -- write " \
          "operations will be logged but not executed")
        expect(subject.main).to be_nil
      end
    end

    context 'when the dry-run option is false' do
      let(:options) { defaults.merge(dry_run: false) }

      it 'safely invokes the given operation' do
        expect(::Uploads::Cleaner).to receive(:new).and_return(cleanup)
        expect(cleanup).to receive(:clean)
        expect(subject.main).to be_nil
      end
    end
  end
end

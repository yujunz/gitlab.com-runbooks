# frozen_string_literal: true

require 'spec_helper'

require_relative '../scripts/registry_search.rb'

describe ::Registry::Storage do
  subject { described_class.new(options) }
  let(:args) { { operation: :delete } }
  let(:defaults) { ::Registry::Config::DEFAULTS.dup.merge(args) }
  let(:options) { defaults }
  let(:age) { DateTime.now - 31 }
  let(:gcs_file) { double('Google::Cloud::Storage::File', name: 'test/path', created_at: age) }
  let(:files) { [gcs_file] }
  let(:client) { double('Google::Cloud::Storage') }
  let(:bucket) { double('Google::Cloud::Storage::Bucket') }

  before do
    allow(gcs_file).to receive(:delete)
    allow(bucket).to receive(:files).and_return(files)
    allow(client).to receive(:bucket).and_return(bucket)
    allow(subject).to receive(:google_cloud_storage_client).and_return(client)
  end

  describe '#safely_invoke_operation' do
    context 'when the dry-run option is true' do
      it 'logs a dry-run informational message' do
        expect(subject.log).to receive(:info).with("[Dry-run] Would have invoked delete on #{gcs_file.name}")
        expect(gcs_file).to receive(:delete).exactly(0).times
        expect(subject.safely_invoke_operation(gcs_file)).to be_nil
      end
    end

    context 'when the dry-run option is false' do
      let(:options) { defaults.merge(dry_run: false) }

      it 'logs the operation and executes it' do
        allow(subject).to receive(:filter_by_age).exactly(1).times.and_yield(gcs_file)
        expect(subject).to receive(:options).exactly(2).times.and_return(options)
        expect(subject.log).to receive(:info).with("Invoking delete on #{gcs_file.name}")
        expect(gcs_file).to receive(options[:operation]).exactly(1).times
        expect(subject.safely_invoke_operation(gcs_file)).to be_nil
      end
    end
  end

  describe '#filter_by_age' do
    context 'when the file age is too small' do
      let(:age) { DateTime.now - 29 }

      it 'yields no file' do
        expect { |file| subject.filter_by_age(&file) }.not_to yield_with_args
      end
    end

    context 'when the file age is large enough' do
      it 'yields the file' do
        expect { |file| subject.filter_by_age(&file) }.to yield_with_args(gcs_file)
      end
    end
  end
end

describe ::Registry::SearchScript do
  subject { Object.new.extend(Registry::SearchScript) }
  let(:args) { { operation: :delete } }
  let(:defaults) { ::Registry::Config::DEFAULTS.dup.merge(args) }
  let(:options) { defaults }
  let(:age) { DateTime.now - 31 }
  let(:gcs_file_fields) { { name: 'test/path', created_at: age } }
  let(:storage) { double('::Registry::Storage') }
  let(:gcs_file) { double('Google::Cloud::Storage::File', **gcs_file_fields) }

  before do
    allow(subject).to receive(:parse).and_return(options)
  end

  describe '#main' do
    context 'when the dry-run option is true' do
      it 'logs the given operation' do
        expect(::Registry::Storage).to receive(:new).and_return(storage)
        expect(storage).to receive(:filter_by_age).and_yield(gcs_file)
        expect(storage).to receive(:safely_invoke_operation).with(gcs_file).and_return nil
        expect(subject.log).to receive(:info).with("[Dry-run] This is only a dry-run -- write " \
          "operations will be logged but not executed")
        expect(subject.log).to receive(:info).with(JSON.pretty_generate(gcs_file_fields))
        expect(subject.main).to be_nil
      end
    end

    context 'when the dry-run option is false' do
      let(:options) { defaults.merge(dry_run: false) }

      it 'safely invokes the given operation' do
        expect(::Registry::Storage).to receive(:new).and_return(storage)
        expect(storage).to receive(:filter_by_age).and_yield(gcs_file)
        expect(storage).to receive(:safely_invoke_operation).with(gcs_file).and_return nil
        expect(subject.log).to receive(:info).with(JSON.pretty_generate(gcs_file_fields))
        expect(subject.main).to be_nil
      end
    end
  end
end

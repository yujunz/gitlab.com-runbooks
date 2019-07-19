# frozen_string_literal: true

require 'spec_helper'

describe KubernetesRules::Validate do
  describe '#yaml_valid?' do
    let(:yaml) { described_class.new }

    it 'validates yaml' do
      file = 'valid-yaml'
      expect(YAML).to receive(:load_file).with(file).and_return(true)
      result = yaml.yaml_valid?(file)

      expect(result).to eq(true)
    end

    it 'reports invalid yaml' do
      file = 'invalid-yaml'
      expect(YAML).to receive(:load_file).with(file).and_raise(
        StandardError.new('error')
      )

      result = yaml.yaml_valid?(file)

      expect(result).to eq(false)
    end
  end

  describe '#valid_rules?' do
    let(:yaml) { described_class.new }

    it 'validates rules' do
      file = 'valid-rules'
      rendered_template = YAML.safe_load('{spec: {groups: [rules: [foo: "hi"]]}}')
      expect(YAML).to receive(:load_file).with(file).and_return(rendered_template)
      result = yaml.rules_valid?(file)

      expect(result).to eq(true)
    end

    it 'reports invalid rules' do
      file = 'invalid-rules'
      rendered_template = YAML.safe_load('{spec: {groups: [rules: [foo: {}]]}}')
      expect(YAML).to receive(:load_file).with(file).and_return(rendered_template)
      result = yaml.rules_valid?(file)

      expect(result).to eq(false)
    end

    it 'skip known objects that are not strings' do
      file = 'string-skip'
      rendered_template = YAML.safe_load('{spec: {groups: [rules: [labels: {}, annotations: {}]]}}')
      expect(YAML).to receive(:load_file).with(file).and_return(rendered_template)
      result = yaml.rules_valid?(file)

      expect(result).to eq(true)
    end
  end
end

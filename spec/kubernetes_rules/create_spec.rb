# frozen_string_literal: true

require 'spec_helper'

describe KubernetesRules::Create do
  describe '#generate_rule_name' do
    let(:rule) { described_class.new }

    it 'sets the name of the rule properly' do
      rf = rule.generate_rule_name('foobar.yml')
      expect(rf).to eq('foobar')

      rh = rule.generate_rule_name('foo-bar.yml')
      expect(rh).to eq('foo-bar')

      ru = rule.generate_rule_name('foo_bar.yml')
      expect(ru).to eq('foo-bar')
    end

    it 'creates our desired demplate' do
      vars = OpenStruct.new(
        rule_name: 'foobar',
        template: <<~ENDOFRULESPEC
          global:
            - rule: expression
        ENDOFRULESPEC
      )

      result = rule.render_for_k8s(vars)

      expected_result = <<~ENDOFEXPECT
        ---
        apiVersion: monitoring.coreos.com/v1
        kind: PrometheusRule
        metadata:
          name: foobar
          labels:
            app: prometheus-operator
            release: gitlab-monitoring
        spec:
          global:
          - rule: expression

      ENDOFEXPECT

      expect(result).to eq(expected_result)
    end
  end
end

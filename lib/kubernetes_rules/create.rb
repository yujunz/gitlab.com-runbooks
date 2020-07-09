#!/usr/bin/env ruby
# frozen_string_literal: true

module KubernetesRules
  # Create will render our template files
  class Create
    def initialize(input_dir: './rules', output_dir: './rules-k8s')
      @input_dir = input_dir
      @output_dir = output_dir
    end

    def create!
      files = Dir.glob("#{@input_dir}/*.yml")

      files.each do |file_path|
        file_name = File.basename(file_path)
        puts "Rendering #{file_name}"

        output_file = "#{@output_dir}/#{file_name}"
        rule_name = generate_rule_name(file_name)
        template_variables = gather_vars(file_path, rule_name)
        rendered_template = render_for_k8s(template_variables)

        File.write(output_file, rendered_template)
      end
    end

    def generate_rule_name(file_name)
      puts file_name
      file_name.match('[\w\-_]+')[0].tr('_', '-')
    end

    def gather_vars(file, rule_name)
      template = File.readlines(file).each(&:chomp).join('  ')

      OpenStruct.new(rule_name: rule_name, template: template)
    end

    def render_for_k8s(template_vars)
      k8s_template = <<~ENDOFEXPECT
        ---
        apiVersion: monitoring.coreos.com/v1
        kind: PrometheusRule
        metadata:
          name: <%= rule_name %>
          labels:
            app: prometheus-operator
            release: gitlab-monitoring
        spec:
          <%= template %>
      ENDOFEXPECT
      render_k8s = ERB.new(k8s_template)
      render_k8s.result(template_vars.instance_eval { binding })
    end
  end
end

#!/usr/bin/env ruby

# frozen_string_literal: true

require 'erb'

# rubocop:disable Lint/UselessAssignment
slack_hook = ENV.fetch('AM_SLACK_HOOK_URL')
snitch_hook = ENV.fetch('AM_SNITCH_HOOK_URL')
prod_pagerduty = ENV.fetch('AM_PAGERDUTY_PROD')
non_prod_pagerduty = ENV.fetch('AM_PAGERDUTY_NON_PROD')
slo_dr = ENV.fetch('AM_SLO_DR')
slo_gprd_cny = ENV.fetch('AM_SLO_GPRD_CNY')
slo_gprd_main = ENV.fetch('AM_SLO_GPRD_MAIN')
slo_non_prod = ENV.fetch('AM_SLO_NON_PROD')
# rubocop:enable Lint/UselessAssignment

def render_for_chef
  @template_locations = ['/opt/prometheus/alertmanager/templates/*.tmpl']

  alertmanager_template = File
                          .readlines('alertmanager.yml.erb')
                          .each(&:chomp)
                          .join

  renderer_for_chef = ERB.new(alertmanager_template)
  File.write('chef_alertmanager.yml', renderer_for_chef.result)
end

def k8s_template
  %(---

alertmanager:
  config:
    <%= @k8s_alertmanager_template %>
  )
end

def render_for_k8s
  alertmanager_template = File
                          .readlines('alertmanager.yml.erb')
                          .each(&:chomp)
                          .join('    ')

  @template_locations = ['/etc/alertmanager/config/*.tmpl']

  initial_renderer_for_k8s = ERB.new(alertmanager_template)
  @k8s_alertmanager_template = initial_renderer_for_k8s.result

  render_k8s = ERB.new(k8s_template)
  File.write('k8s_alertmanager.yaml', render_k8s.result)
end

render_for_chef
render_for_k8s

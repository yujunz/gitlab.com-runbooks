#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/kubernetes_rules'

require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.on('--create', TrueClass, 'Create the rendered configurations') do |c|
    options[:create] = c
  end

  opts.on('--validate', TrueClass, 'Validate the rendered configurations') do |v|
    options[:validate] = v
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

# Create from the "all" shards rules dir.
KubernetesRules::Create.new.create! if options[:create]
# Create from the "default" shard rules dir. There is currently only one K8s shard,
# so output into the same dir as the "all" rules.
KubernetesRules::Create.new(input_dir: "./rules/default").create! if options[:create]
KubernetesRules::Validate.new.validate! if options[:validate]

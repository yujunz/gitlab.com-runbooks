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

KubernetesRules::Create.new.create! if options[:create]
KubernetesRules::Validate.new.validate! if options[:validate]

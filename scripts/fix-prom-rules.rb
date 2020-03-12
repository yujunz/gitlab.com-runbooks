#!/usr/bin/env ruby
# frozen_string_literal: true
require 'yaml'

KEY_ORDER = %w[
  name
  interval
  rules
  alert
  for
  annotations
  record
  labels
  expr
].freeze

def reorder(item)
  case item
  when Hash
    reorder_hash(item)
  when Array
    reorder_array(item)
  else
    item
  end
end

# Reorder the items in the hash according to the order listed in KEY_ORDER
def reorder_hash(hash)
  hash.transform_values { |v| reorder(v) }.sort_by { |k, _| KEY_ORDER.index(k) || KEY_ORDER.size }.to_h
end

def reorder_array(array)
  array.collect { |i| reorder(i) }
end

doc = YAML.safe_load(ARGF.read)
STDOUT.print reorder(doc).to_yaml(line_width: 100).gsub("---\n", '')

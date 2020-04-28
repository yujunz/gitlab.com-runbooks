#!/usr/bin/env ruby
# frozen_string_literal: true
require 'yaml'

KEY_ORDER = %w[
  name
  interval
  partial_response_strategy
  rules
  alert
  for
  annotations
  record
  labels
  expr
  title
  description
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

def cmp_keys(key_a, key_b)
  i_a = KEY_ORDER.index(key_a)
  i_b = KEY_ORDER.index(key_b)

  return i_a - i_b if i_a && i_b # Both keys have fixed positions
  return -1 if i_a # key_a is indexed
  return 1 if i_b # key_b is indexed

  # neither key is indexed, sort lexographically
  key_a.casecmp(key_b)
end

# Reorder the items in the hash according to the order listed in KEY_ORDER
def reorder_hash(hash)
  hash.transform_values { |v| reorder(v) }
      .sort { |a, b| cmp_keys(a[0], b[0]) }
      .to_h
end

def reorder_array(array)
  array.collect { |i| reorder(i) }
end

doc = YAML.safe_load(ARGF.read)
STDOUT.print reorder(doc).to_yaml(line_width: 100).gsub("---\n", '')

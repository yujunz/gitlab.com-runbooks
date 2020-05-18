#! /usr/bin/env ruby
# frozen_string_literal: true

# script for parsing output from elasticsearch's _nodes/hot_threads endpoint
# and collapsing the stacks to a format that can be piped into flamegraph.pl.
#
# example usage:
#  curl -s "$ELASTICSEARCH_URL/_nodes/hot_threads" > hot_threads
#  cat hot_threads | scripts/collapse_hot_threads.rb | scripts/flamegraph.pl > hot_threads.svg
#
# some notes on hot_threads behaviour and parameters:
#
#   the way the hot_threads endpoint captures stacks is not on-cpu stacks across
#   all threads as one might expect.
#
#   it takes two snapshots of "time on cpu" counters of all threads, 500ms apart
#   (this is the interval). then it picks the top k of those threads (interval
#   and k are configurable).
#
#   for those top k threads it collects n stack samples at 100hz (n is configurable).
#
#   you can configure type as "block", "cpu", or "wait". the default is "cpu".
#   this will only affect the scoring of which threads to sample.
#
#   the sampling of stacks is done via `ThreadMXBean.getThreadInfo()`. this
#   will sample regardless of whether that thread is on CPU or not.
#
# see also:
#   https://www.elastic.co/guide/en/elasticsearch/reference/current/cluster-nodes-hot-threads.html

require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: collapse_hot_threads.rb [options]"

  opts.on('', '--node', 'include node name in stack') { |v| options[:node] = v }
  opts.on('', '--index', 'include index name in stack') { |v| options[:index] = v }
end.parse!

lines = ARGF.readlines.map(&:rstrip)

nodes = []

# ::: {instance-0000000069}{e-qNvKuUSQqvQOB-5-lZjA}{9CsD0cc_QcKWMJw3BEcRYg}{10.42.0.198}{10.42.0.198:19665}{m}{logical_availability_zone=zone-2, server_name=instance-0000000069.92c87c26b16049b0a30af16b94105528, availability_zone=us-central1-a, xpack.installed=true, region=unknown-region, instance_configuration=gcp.master.1}

loop do
  break if lines.size == 0

  l = lines.shift
  raise 'start with :::' unless l.start_with?(':::')
  raise unless /::: (\{.*\})+/.match(l)

  m = l.scan(/\{([^}]*)\}/)
  raise unless m

  # ["instance-0000000069", "e-qNvKuUSQqvQOB-5-lZjA", "9CsD0cc_QcKWMJw3BEcRYg", "10.42.0.198", "10.42.0.198:19665", "m", "logical_availability_zone=zone-2, server_name=instance-0000000069.92c87c26b16049b0a30af16b94105528, availability_zone=us-central1-a, xpack.installed=true, region=unknown-region, instance_configuration=gcp.master.1"]

  matches = m.map(&:first)
  node_name, node_id, _, node_ip, node_hostport, node_role, attrs = matches
  attrs = attrs.split(', ').map { |attr| attr.split('=', 2) }.to_h

  node = {
    name: node_name,
    attrs: attrs,
    threads: [],
  }

  # Hot threads at 2020-05-14T14:33:30.334Z, interval=500ms, busiestThreads=3, ignoreIdleThreads=true:

  l = lines.shift
  raise 'hot threads' unless m = /^   Hot threads at (\S+), interval=(\S+), busiestThreads=(\S+), ignoreIdleThreads=(\S+):$/.match(l)

  timestamp, interval, busiest, ignore_idle = m.to_a[1..]

  node[:profile] = {
    timestamp: timestamp,
    interval: interval,
    busiest: busiest,
    ignore_idle: ignore_idle,
  }

  # 94.8% (473.8ms out of 500ms) cpu usage by thread 'elasticsearch[instance-0000000069][generic][T#21]'

  loop do
    l = lines.shift
    raise 'expected blank' unless l == ''

    break 2 if lines.size == 0

    break if lines.first.start_with?(':::')

    l = lines.shift
    raise 'thread name' unless m = /^\s+(\S+)% \((\S+) out of (\S+)\) cpu usage by thread '([^']+)'$/.match(l)

    percent, time_est, time_total, thread_name = m.to_a[1..]

    # elasticsearch[instance-0000000047][[pubsub-rails-inf-gprd-002977][5]: Lucene Merge Thread #1130]
    # elasticsearch[instance-0000000056][write][T#5]
    # QuotaAwareFSTimer-0

    index_name = nil

    if m = /^elasticsearch\[(\S+)\]\[\[(\S+)\]\[(\S+)\]: (.+)\]$/.match(thread_name)
      index_name = m[2]
      thread_name = m[4]
    elsif m = /^elasticsearch\[(\S+)\]\[(\S+)\]\[(\S+)\]$/.match(thread_name)
      thread_name = m[2]
    end

    if /^Lucene Merge Thread #\d+$/.match(thread_name)
      thread_name = 'Lucene Merge Thread'
    end

    thread = {
      percent: percent,
      time_est: time_est,
      time_total: time_total,
      name: thread_name,
      index_name: index_name,
      samples: [],
    }

    #     3/100 snapshots sharing following 34 elements

    loop do
      break if lines.first == ''

      l = lines.shift
      if l == '     unique snapshot'
        count_seen = 1
        count_total = 1
      else
        raise 'snapshots' unless m = /^     (\S+)\/(\S+) snapshots sharing following (\S+) elements$/.match(l)
        count_seen, count_total, _ = m.to_a[1..]
      end

      sample = {
        count_seen: count_seen,
        count_total: count_total,
        stack: [],
      }

      #        app//org.elasticsearch.action.admin.indices.stats.CommonStats.add(CommonStats.java:373)

      loop do
        break unless lines.first.start_with?('      ')

        l = lines.shift

        sample[:stack] << l.strip
      end

      thread[:samples] << sample
    end

    node[:threads] << thread
  end

  nodes << node
end

raise 'non-consumed lines' unless lines.size == 0

# pp nodes
# exit 1

nodes.each do |node|
  node[:threads].each do |thread|
    thread[:samples].each do |sample|
      stack = []
      stack << node[:name] if options[:node]
      stack << thread[:name]
      stack << thread[:index_name] if options[:index] && thread[:index_name]
      stack += sample[:stack].reject { |f| /(\$\$Lambda\$|^org\.elasticsearch\.xpack\.security\.|Listener\.java:|ListenableFuture\.java:|AbstractRunnable\.java:)/.match(f) }.reverse
      puts "#{stack.join(';')} #{sample[:count_seen]}"
    end
  end
end

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Troubleshooting](#troubleshooting)
    - [Is redis running?](#is-redis-running)
        - [Grafana](#grafana)
        - [Prometheus/Thanos](#prometheusthanos)
        - [directly on a redis host](#directly-on-a-redis-host)
    - [How to get redis stats?](#how-to-get-redis-stats)
        - [Grafana](#grafana-1)
        - [Prometheus/Thanos](#prometheusthanos-1)
        - [redis-cli](#redis-cli)
    - [What is causing Redis to slowdown?](#what-is-causing-redis-to-slowdown)
        - [Prometheus/Thanos/Grafana](#prometheusthanosgrafana)
        - [slowlog](#slowlog)
            - [Monitoring number of slowlog entries](#monitoring-number-of-slowlog-entries)
            - [Monitoring the rate of change in the slowlog](#monitoring-the-rate-of-change-in-the-slowlog)
        - [Redis latency monitoring framework](#redis-latency-monitoring-framework)
            - [LATENCY DOCTOR](#latency-doctor)
        - [generic debugging/troubleshooting tools](#generic-debuggingtroubleshooting-tools)
            - [gdb](#gdb)
        - [redis-cli sub-commands](#redis-cli-sub-commands)
            - [--latency](#latency)
            - [--latency-history](#latency-history)
            - [--latency-dist](#latency-dist)
            - [--bigkeys (find biggest keys)](#bigkeys-find-biggest-keys)
            - [--scan (get a list of keys matching a pattern)](#scan-get-a-list-of-keys-matching-a-pattern)
        - [Get the number of connections per Redis client IP](#get-the-number-of-connections-per-redis-client-ip)
        - [redis-memory-analyzer](#redis-memory-analyzer)
        - [analyze memory usage on redis](#analyze-memory-usage-on-redis)
        - [Analyze network traffic on a Redis host](#analyze-network-traffic-on-a-redis-host)
            - [Capture traffic and download it to your local machine](#capture-traffic-and-download-it-to-your-local-machine)
            - [Split the packet capture using tcpflow](#split-the-packet-capture-using-tcpflow)
            - [Analyze Redis traffic](#analyze-redis-traffic)
                - [count redis commands](#count-redis-commands)
            - [Please remember to delete the `pcap` file immediately after performing the analysis](#please-remember-to-delete-the-pcap-file-immediately-after-performing-the-analysis)
        - [packetbeat](#packetbeat)
        - [Profiling the application](#profiling-the-application)
- [Failover and Recovery procedures](#failover-and-recovery-procedures)
    - [Accessing the Redis console](#accessing-the-redis-console)
    - [Building a new Redis server and starting replication](#building-a-new-redis-server-and-starting-replication)
        - [Discussion](#discussion)
    - [Ban an IP with Rails Rack Attack (which uses redis)](#ban-an-ip-with-rails-rack-attack-which-uses-redis)
    - [Replication issues](#replication-issues)
        - [Possible checks](#possible-checks)
            - [client-output-buffer-limit](#client-output-buffer-limit)
            - [Checks Using Prometheus](#checks-using-prometheus)
                - [Redis Primaries](#redis-primaries)
                - [Redis Secondaries](#redis-secondaries)
                - [Redis Replication Lag](#redis-replication-lag)
                - [Redis Replication Events](#redis-replication-events)
            - [Redis Sentinel](#redis-sentinel)
                - [Get Redis master](#get-redis-master)
                - [Get Redis slaves](#get-redis-slaves)
                - [Get Sentinel machines](#get-sentinel-machines)
            - [Redis console](#redis-console)
                - [Replication status](#replication-status)
                - [Master/slave role of the redis node](#masterslave-role-of-the-redis-node)
        - [Resolution](#resolution)
        - [Helpful Resources](#helpful-resources)
    - [Switch Master manually](#switch-master-manually)
        - [How to manually switch primaries](#how-to-manually-switch-primaries)
    - [Replication flapping](#replication-flapping)
        - [Possible causes](#possible-causes)
        - [Possible fixes](#possible-fixes)
    - [Redis is down](#redis-is-down)
        - [Start Redis](#start-redis)
    - [Failed to collect Redis metrics](#failed-to-collect-redis-metrics)
        - [Symptoms](#symptoms)
        - [Possible checks](#possible-checks-1)
        - [Solution](#solution)
- [References](#references)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


# Troubleshooting #

## Is redis running? ##

### Grafana ###

Grafana dashboards:
- [redis](https://dashboards.gitlab.net/d/redis-main/redis-overview?orgId=1&from=now-6h&to=now)
- [redis-cache](https://dashboards.gitlab.net/d/redis-cache-main/redis-cache-overview?orgId=1&from=now-6h&to=now)
- [redis-sidekiq](https://dashboards.gitlab.net/d/redis-sidekiq-main/redis-sidekiq-overview?orgId=1&from=now-6h&to=now)


For example, there is a Grafana chart showing number of slowlog events in redis-sidekiq (not linking it here because the panel ID changes when Grafana dashboards are deployed).

### Prometheus/Thanos ###

https://thanos-query.ops.gitlab.net/graph?g0.range_input=1w&g0.expr=redis_up%20%3C%201&g0.tab=0

### directly on a redis host ###

* is redis up?
  * `gitlab-ctl status`
* can we dial redis?
  * `telnet localhost 6379`
* can we talk to redis via `redis-cli`?

```
REDISCLI_AUTH=$(sudo grep ^masterauth /var/opt/gitlab/redis/redis.conf|cut -d\" -f2)
/opt/gitlab/embedded/bin/redis-cli info
```

## How to get redis stats? ##

### Grafana ###

[see above](#grafana-dashboards)

### Prometheus/Thanos ###

Redis hosts are running the `redis_exporter` . It is scraped by Prometheus. See [the exporter documentation](https://github.com/oliver006/redis_exporter) for more details.

[Example `redis_exporter` metric](https://thanos-query.ops.gitlab.net/graph?g0.range_input=1h&g0.max_source_resolution=0s&g0.expr=redis_commands_processed_total&g0.tab=1) in Thanos.

### redis-cli ###

Run:
- [INFO command](https://redis.io/commands/info)
- [MEMORY_STATS command](https://redis.io/commands/memory-stats)

NOTE: DO NOT USE [MONITOR] COMMAND! It streams back every command processed by the Redis server which can double the use of resources. It can overload a production machine making it unresponsive or causing an OOM kill.

NOTE: DO NOT USE [KEYS] COMMAND! It will overload a production machine.

## What is causing Redis to slowdown? ##

The application relies on Redis throughput to be very high, latency spikes can be detrimental to the operation of the entire application.

### Prometheus/Thanos/Grafana ###

Explore Prometheus/Thanos/Grafana. Historical metrics might suggest a sudden change in the application behavior or traffic, for example:
- operations rate, 7d: https://dashboards.gitlab.net/d/redis-cache-main/redis-cache-overview?orgId=1&from=now-7d&to=now&fullscreen&panelId=54
- keys rate of change, 7d: https://dashboards.gitlab.net/d/redis-cache-main/redis-cache-overview?orgId=1&from=now-7d&to=now&fullscreen&panelId=64

For Grafana links [see above](#grafana-dashboards).

### slowlog ###

The slowlog records slow Redis queries.

Redis [SLOWLOG command documentation](https://redis.io/commands/slowlog).

Get top 10 Redis slowlog entries:
```shell
> slowlog get 10
1) 1) (integer) 5100            # A unique progressive identifier for every slow log entry.
   2) (integer) 1561019091      # The unix timestamp at which the logged command was processed.
   3) (integer) 21390           # The amount of time needed for its execution, in microseconds.
   4) 1) "del"                  # The array composing the arguments of the command.
      2) "cache:gitlab:242234:8213877:Ci::CompareTestReportsService"
```

To convert the timestamp, use `date -d @1561019091`.

Get the command execution time threshold at which commands are logged (in microseconds):
```
> config get slowlog-log-slower-than
```

Get size of slowlog (entries are discarded like in a FIFO queue):
```
> config get slowlog-max-len
```

#### Monitoring number of slowlog entries ####

The number of entries added to the slowlog is exposed as a Prometheus metric and [there is a Grafana chart for it](https://dashboards.gitlab.net/d/redis-sidekiq-main/redis-sidekiq-overview?orgId=1&from=now-6h&to=now&fullscreen&panelId=48).

#### Monitoring the rate of change in the slowlog ####

A useful metric for monitoring potential slow-downs in Redis is measuring the rate of change in the `redis_slowlog_last_id`.

This can be done by plotting (`changes(redis_slowlog_last_id[1h])`](https://prometheus.gprd.gitlab.net/graph?g0.range_input=1d&g0.expr=changes(redis_slowlog_last_id%5B1h%5D)&g0.tab=0).

### Redis latency monitoring framework ###

Redis provides a latency diagnostic tool: https://redis.io/topics/latency-monitor

You may need to enable it with `CONFIG SET latency-monitor-threshold 100`.

From https://redis.io/topics/latency-monitor :

> By default monitoring is disabled (threshold set to 0), even if the actual cost of latency monitoring is near zero. However while the memory requirements of latency monitoring are very small, there is no good reason to raise the baseline memory usage of a Redis instance that is working well.

#### LATENCY DOCTOR ####


```shell
> CONFIG SET latency-monitor-threshold 100
> LATENCY DOCTOR
Dave, I have observed latency spikes in this Redis instance.
You don't mind talking about it, do you Dave?

1. command: 5 latency spikes (average 300ms, mean deviation 120ms,
   period 73.40 sec). Worst all time event 500ms.

I have a few advices for you:

- Your current Slow Log configuration only logs events that are
  slower than your configured latency monitor threshold. Please
  use 'CONFIG SET slowlog-log-slower-than 1000'.
- Check your Slow Log to understand what are the commands you are
  running which are too slow to execute. Please check
  http://redis.io/commands/slowlog for more information.
- Deleting, expiring or evicting (because of maxmemory policy)
  large objects is a blocking operation. If you have very large
  objects that are often deleted, expired, or evicted, try to
  fragment those objects into multiple smaller objects.

 > CONFIG SET latency-monitor-threshold 0
```

### generic debugging/troubleshooting tools ###

#### gdb ####

https://redis.io/topics/debugging

### redis-cli sub-commands ###

#### --latency ####

#### --latency-history ####

`redis-cli` has a useful command-line argument `--latency-history` that
issues PING commands to a Redis server to measure its
responsiveness. For example:

```
$ /opt/gitlab/embedded/bin/redis-cli --latency-history  -h 10.217.5.102
min: 0, max: 67, avg: 8.65 (799 samples) -- 15.00 seconds range
min: 0, max: 62, avg: 9.03 (783 samples) -- 15.01 seconds range
min: 0, max: 50, avg: 8.53 (802 samples) -- 15.00 seconds range
min: 0, max: 61, avg: 7.96 (830 samples) -- 15.02 seconds range
min: 0, max: 110, avg: 7.32 (860 samples) -- 15.01 seconds range
min: 0, max: 30, avg: 2.28 (1206 samples) -- 15.00 seconds range
min: 0, max: 82, avg: 5.39 (966 samples) -- 15.01 seconds range
min: 0, max: 108, avg: 19.62 (504 samples) -- 15.00 seconds range
min: 0, max: 57, avg: 13.87 (625 samples) -- 15.01 seconds range
min: 0, max: 57, avg: 7.82 (836 samples) -- 15.03 seconds range
min: 0, max: 45, avg: 5.28 (972 samples) -- 15.00 seconds range
```

This test will run indefinitely until you kill it, but the `avg` time here
is important. The first line shows that on average, a single Redis command
took 8 ms to respond--too slow! A healthy looking run returns averages well
under a millisecond:

```
$ /opt/gitlab/embedded/bin/redis-cli --latency-history  -h  10.217.5.101
min: 0, max: 1, avg: 0.10 (1472 samples) -- 15.01 seconds range
min: 0, max: 1, avg: 0.10 (1470 samples) -- 15.00 seconds range
min: 0, max: 2, avg: 0.10 (1470 samples) -- 15.00 seconds range
min: 0, max: 2, avg: 0.11 (1470 samples) -- 15.01 seconds range
min: 0, max: 2, avg: 0.11 (1471 samples) -- 15.01 seconds range
```

There may be a number of causes for the latency:

1. Number of client connections: check the number of active TCP connections on the Redis host.
2. Slow background saves
3. Key evictions

See https://tech.trivago.com/2017/01/25/learn-redis-the-hard-way-in-production/ more information.

#### --latency-dist ####

#### --bigkeys (find biggest keys)

(uses SCAN command)

#### --scan (get a list of keys matching a pattern)

`redis-cli -a $REDIS_PASS --scan --patern "resque:*"`

### Get the number of connections per Redis client IP ###

On a redis host:
```
$ sudo lsof -i tcp:6379 | grep ESTABLISHED | sed -E "s/.*6379->(.*):.* \(ESTABLISHED\)/\1/g" | sort | uniq -c | sort -nr
```

### redis-memory-analyzer ###

https://github.com/gamenet/redis-memory-analyzer

### analyze memory usage on redis

```
$ rdb -c memory dump.rdb | ruby redis-analysis-tool.rb
$ cat redis-analysis-tool.rb

  count = 0

  sizes = { }

  ARGF.each do |line|

    next unless line =~ /^\d+,string,(\w+):.*?,(\d+)/

    sizes[$1] = (sizes[$1] || 0) + $2.to_i

    count = count + 1

    if (sizes.keys.size > 10000) || (count % 100000 == 0) then

      sizes.each do |key, size|

        puts "#{key}:#{size}\n"

        sizes = { }

      end

    end

  end

  sizes.each do |key, size|

    puts "#{key}:#{size}\n"

    sizes = { }

  end
```

### Analyze network traffic on a Redis host ###

This guide describes a technique that will not have a major performance
impact on a Redis host. It consists of the following:

1. Capture Redis traffic using `tcpdump`.
2. Split the packet capture into separate flows using [tcp-flow](https://github.com/simsong/tcpflow/).
3. Run a custom script to aggregate the results.

#### Capture traffic and download it to your local machine ####

On the *master* Redis server, capture TCP packets and compress them with the following commands:

```shell
$ df -Th /var/log # confirm there's enough disk space

$ sudo mkdir -p /var/log/pcap-$USER
$ cd /var/log/pcap-$USER
$ sudo chown $USER:$USER .

$ sudo tcpdump -G 30 -W 1 -s 65535 tcp port 6379 -w redis.pcap -i ens4
tcpdump: listening on ens4, link-type EN10MB (Ethernet), capture size 65535 bytes
676 packets captured
718 packets received by filter
0 packets dropped by kernel
```

It may be cheaper to capture only incoming traffic:

```
$ sudo tcpdump -G 30 -W 1 -s 65535 tcp dst port 6379 -w redis.pcap -i ens4
```

Compression:

```
$ gzip redis.pcap
```

now download the capture with:
```shell
$ scp redis-cache-01-db-gstg.c.gitlab-staging-1.internal:redis.pcap.gz .
```

remember to remove the pcap file once you're done!

#### Split the packet capture using tcpflow ####

1. install tcpflow (on MacOS: `brew install tcpflow`)
1. split the packet capture into separate tcpflows:
```shell
$ tcpflow -I -s -o redis-analysis -r redis.pcap.gz
$ cd redis-analysis
```

#### Analyze Redis traffic ####

##### count redis commands #####

Get the number of commands send to redis:
```shell
$ find . -name '*.06379'|xargs -n 1 perl -0777  -pe 's/\*\d+\r\n\$\d+\r\n(\w+)\r\n\$\d+\r\n([\w\d:]+)/command: $1 $2/gsx;'|grep -a '^command'|grep -v "command: auth "|sort|uniq -c|sort -nr > ./script_report
$ less ./script_report
70334 command: setex peek:requests:
69205 command: get cache:gitlab:geo:current_node:12.0.0-pre:5.1.7
69178 command: get cache:gitlab:geo:node_enabled:12.0.0-pre:5.1.7
65642 command: get cache:gitlab:flipper/v1/feature/enforced_sso_requires_session
(...)
```

##### keyspace analysis #####

The redis trace script parses out flows into a timeline of commands, one line per key. The fields are: timestamp, second offset, command, src host, key pattern, key.

The script can be tweaked or its output further processed with `awk` and friends.

```shell
$ find redis-analysis -name '*.06379.findx' | parallel -j0 -n100 ruby runbooks/scripts/redis_trace_cmd.rb | sed '/^$/d' > trace.txt
$ gsort --parallel=8 trace.txt -o trace.txt
```

For example, count per key pattern:

```shell
$ cat trace.txt | awk '{ print $5 } | sort -n | uniq -c | sort -nr'
```

#### Please remember to delete the `pcap` file immediately after performing the analysis ####

### CPU profiling ###

CPU profiles are useful for diagnosing CPU saturation. Especially since redis is (mostly) single-threaded, CPU can become a bottleneck.

A profile can be captured via perf:

```shell
$ sudo mkdir -p /var/log/perf-$USER
$ cd /var/log/perf-$USER
$ sudo chown $USER:$USER .

$ sudo perf record -p $(pidof redis-server) -F 497 --call-graph dwarf --no-inherit -- sleep 300
$ sudo perf script --header | gzip > stacks.$(hostname).$(date --iso-8601=seconds).gz
$ sudo rm perf.data
```

This will sample stacks at ~500hz.

Those stack traces can then be downloaded and analyzed with [flamescope](https://github.com/Netflix/flamescope) or [flamegraph](https://github.com/brendangregg/FlameGraph).

```shell
$ scp $host:/var/log/perf-\*/stacks.\*.gz .
$ cat stacks.$host.$time.gz | gunzip - | ~/code/FlameGraph/stackcollapse-perf.pl | ~/code/FlameGraph/flamegraph.pl > flamegraph.svg
```

### packetbeat

TODO https://github.com/elastic/beats/tree/master/packetbeat

### Profiling the application ###

TODO e.g. rbspy, will be partially covered by https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/6940

# Failover and Recovery procedures #

## Accessing the Redis console ##

Be extremely careful with Redis! There are commands such as KEYS or MONITOR that can lock Redis entirely without any warning. The application relies heavily on cache so locking Redis will result in an immediate downtime.

Redis admin password is stored in the omnibus cookbook secrets in GKMS, and it's deployed to gitlab config file: /etc/gitlab/gitlab.rb (this file then gets translated into multiple other config files, including redis.conf)

interactive:
```
REDISCLI_AUTH=$(sudo grep ^masterauth /var/opt/gitlab/redis/redis.conf|cut -d\" -f2) /opt/gitlab/embedded/bin/redis-cli
```

or oneliners:
```
REDISCLI_AUTH=$(sudo grep ^masterauth /var/opt/gitlab/redis/redis.conf|cut -d\" -f2) /opt/gitlab/embedded/bin/redis-cli slowlog get 10
```

## Building a new Redis server and starting replication

NOTE: These instructions are for setting up Redis *Sentinel*: https://redis.io/topics/sentinel . NOT for setting up Redis *Cluster*: https://redis.io/topics/cluster-tutorial

From time to time you may have to build (or rebuild) a redis cluster. While the omnibus documentation (https://docs.gitlab.com/ee/administration/high_availability/redis.html) says everything should start replicating by magic, it doesn't in our builds because we touch /etc/gitlab/skip-autoreconfigure on redis nodes, so that restarts during upgrades can be done in a more controlled fashion across multiple nodes.

So, after building the nodes, there are some manual steps to take:

1. On all nodes, `sudo gitlab-ctl reconfigure`
   * This will reconfigure/start up redis, but not sentinel
1. On all nodes, `sudo gitlab-ctl start sentinel`
   * Not sure why, but it's minor
1. On the replicas, start replicating from the master:
   1. REDISCLI_AUTH=$(sudo grep ^masterauth /var/opt/gitlab/redis/redis.conf|cut -d\\" -f2)
   1. /opt/gitlab/embedded/bin/redis-cli
   1. 127.0.0.1:6379> slaveof MASTER_IP 6379
   1. 127.0.0.1:6379> info replication

You're now expecting the replica to report something like:
```
role:slave
master_host:MASTER_IP
master_port:6379
```

If you run `info replication` on the master, you expect to see `role:master` and `connected_slaves:2`

### Discussion
Sentinel is supposed to control the replication configuration in redis.conf (the 'slaveof' configuration line); therefore, when omnibus creates redis.conf it really shouldn't add that configuration line, otherwise it and sentinel would end up fighting.  So new redis nodes created with omnibus installed will all think they're master, until they're told otherwise.  We do this above, and at that point, sentinel (connected to the master) becomes aware of the replicas, and starts managing their replication status.

It's a little chicken-and-egg, and humans need to be involved.  It should, however, be one-off at cluster build time.

## Ban an IP with Rails Rack Attack (which uses redis) ##

see: https://gitlab.com/gitlab-com/runbooks/blob/master/docs/redis/ban-an-IP-with-redis.md


## Replication issues

### Possible checks ###

#### client-output-buffer-limit

check Redis docs for more information: https://raw.githubusercontent.com/antirez/redis/5.0/redis.conf

```shell
> config get client-output-buffer-limit
```

#### Checks Using Prometheus ####

##### Redis Primaries #####

List the Redis primaries using:

* [`redis_master_repl_offset > 0`](https://prometheus.gitlab.com/graph?g0.range_input=1h&g0.expr=redis_master_repl_offset%20%3E%200%20&g0.tab=1)

##### Redis Secondaries #####

List the Redis secondaries using:

* [`redis_slave_info`](https://prometheus.gitlab.com/graph?g0.range_input=1h&g0.expr=redis_slave_info&g0.tab=1)

##### Redis Replication Lag #####

Replication lag indicates that the Redis secondaries are struggling to keep up with the changes on the primary. This may be due to the rate of changes on the primary being too high, or the secondaries being under too much load to keep up.

Replication lag is measured in bytes in the replication stream.

https://dashboards.gitlab.net/dashboard/db/andrew-redis?panelId=13&fullscreen&orgId=1

##### Redis Replication Events #####

* Check the Redis Replication Events dashboard to see if Redis is frequently failing over. This may indicate replication issues. https://dashboards.gitlab.net/dashboard/db/andrew-redis?panelId=14&fullscreen&orgId=1

* Master switch events are logged in the redis log, for example:
```shell
$ zcat /var/log/gitlab/redis/@400000005e58927932f8744c.s | grep -i master
2020-02-27_11:35:39.68552 26796:M 27 Feb 2020 11:35:39.685 * MASTER MODE enabled (user request from 'id=267 addr=10.224.8.122:51379 fd=17 name= age=58518 idle=0 flags=x db=0 sub=0 psub=0 multi=3 qbuf=140 qbuf-free=32628 obl=36 oll=0 omem=0 events=r cmd=exec')
```

#### Redis Sentinel ####

NOTE: At the moment of writing, Redis Cluster is not used anywhere in the gitlab.com infrastructure, we only utilize Redis Sentinel.

Redis Sentinel provides compatible clients with a pointer to the current Redis primary. Clients will query Sentinel and then connect directly to the primary Redis (in other words, Sentinel does not proxy requests).

Additionally, Sentinel will reconfigure Redis instances as primary or secondaries, depending on the Sentinel clusters quorum.

For more information see [Sentinel documentation](https://redis.io/topics/sentinel)

Sentinel is configured via `gitlab.rb`:

```shell
$ sudo grep redis_sentinels /etc/gitlab/gitlab.rb
gitlab_rails['redis_sentinels'] = [{"host"=>"10.66.2.101", "port"=>26379}, {"host"=>"10.66.2.102", "port"=>26379}, {"host"=>"10.66.2.103", "port"=>26379}]
```

which gets translated into `/var/opt/gitlab/sentinel/sentinel.conf`.

##### Get Redis master

Once you have the IP of a sentinel, use `redis-cli` to access sentinel. Sentinel usually runs on port `26379` (ie, Redis port (`6379`) + `20000`). The `sentinel masters` command will return a list of Redis primaries managed by this sentinel cluster:

```shell
$ /opt/gitlab/embedded/bin/redis-cli -h 10.66.2.101 -p 26379 sentinel masters
6379 sentinel masters
1)  1) "name"
    2) "gitlab-redis"
    3) "ip"
    4) "10.66.2.103"
    5) "port"
    6) "6379"
    7) "runid"
    8) "6f24caa796eb53afcf3b6a883ca02037892c812e"
    9) "flags"
   10) "master"
   11) "link-pending-commands"
   12) "0"
   13) "link-refcount"
   14) "1"
   15) "last-ping-sent"
   16) "0"
   17) "last-ok-ping-reply"
   18) "125"
   19) "last-ping-reply"
   20) "125"
   21) "down-after-milliseconds"
   22) "10000"
   23) "info-refresh"
   24) "2505"
   25) "role-reported"
   26) "master"
   27) "role-reported-time"
   28) "1540240114"
   29) "config-epoch"
   30) "208"
   31) "num-slaves"
   32) "2"
   33) "num-other-sentinels"
   34) "2"
   35) "quorum"
   36) "2"
   37) "failover-timeout"
   38) "60000"
   39) "parallel-syncs"
   40) "1"
```

A few important details to keep an eye on:

* `name`: the name of the Redis primary/secondaries set. Remember a single Sentinel cluster can manage multiple Redis sets.
* `ip`: the IP of the primary
* `port`: the port of the primary
* `flags`: {+ `master` +} is good. {- `odown` -} (Objectively down, the quorum is in agreement about the host being down) and {- `sdown` -} (Subjectively down, the quorum is in disagreement about the host being down)  are bad.
* `num-other-sentinels`: this should be {+ `3` +} for our Sentinel topology. If this number is different, there may be problems with Sentinel.
* `quorum`: this should be {+ `2` +} for our Sentinel topology.

##### Get Redis slaves

You can also query the list of slaves connected to a sentinel primary using `sentinel slaves <primary-name>`:

```shell
$  /opt/gitlab/embedded/bin/redis-cli -h 10.66.2.102 -p 26379 sentinel slaves gitlab-redis
1)  1) "name"
    2) "10.66.2.102:6379"
    3) "ip"
    4) "10.66.2.102"
    5) "port"
    6) "6379"
    7) "runid"
    8) "664393f67a6c1b5a130c3af52f05429e5d923558"
    9) "flags"
   10) "slave"
   ...
```

##### Get Sentinel machines

[Get Sentinel machines](https://thanos-query.ops.gitlab.net/graph?g0.range_input=1h&g0.max_source_resolution=0s&g0.expr=count%20by%20(env%2C%20type)%20(namedprocess_namegroup_num_procs%7Bgroupname%3D%22redis-sentinel%200.0.0.0%3A26379%20%5Bsentinel%5D%22%7D)&g0.tab=1)


#### Redis console ####

##### Replication status

```shell
> info replication
# Replication
role:master
connected_slaves:4
slave0:ip=10.45.2.8,port=6379,state=online,offset=208856216927,lag=0
slave1:ip=10.45.2.7,port=6379,state=online,offset=208856050552,lag=1
slave2:ip=10.45.2.9,port=6379,state=online,offset=208856088958,lag=1
master_repl_offset:208856228130
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:208855179555
repl_backlog_histlen:1048576
```

In this case we are missing slave3 since we have 4 slaves.

##### Master/slave role of the redis node #####

```shell
> role
1) "master"
2) (integer) 7657965683
3) 1) 1) "10.224.8.102"
      2) "6379"
      3) "7657965683"
   2) 1) "10.224.8.101"
      2) "6379"
      3) "7657965519"
```
### Resolution ###

* Just wait, every slave should automatically restart it's replication when it drops out
* If it takes longer then expected check /var/log/gitlab/redis/current on the mailfunctioning slave for any indications why it won't restart replication

### Helpful Resources ###

* https://redis.io/topics/replication
* https://redis.io/topics/sentinel
* https://redislabs.com/blog/top-redis-headaches-for-devops-replication-buffer/
* https://redislabs.com/blog/top-redis-headaches-for-devops-replication-timeouts/
* https://redislabs.com/blog/top-redis-headaches-for-devops-client-buffers/

## Switch Master manually

### How to manually switch primaries

NOTE: This should have no visible negative impact on the GitLab application.

NOTE: There is no authentication required for interacting with Sentinel.

1. Get current Redis master. On one of the nodes running the redis sentinel (varies by cluster; redis + redis-sidekiq run sentinel on the main redis nodes, redis-cache has its own set of sentinel servers, and this may change in future):

```shell
$ /opt/gitlab/embedded/bin/redis-cli -p 26379 SENTINEL masters
1)  1) "name"
    2) "gstg-redis-cache"        # cluster_id
    3) "ip"
    4) "10.224.8.103"            # ip address of the current master
    5) "port"
    6) "6379"
    7) "runid"
    8) "06277f7abca059c268b2c5e2b2581d7d3bf330f1"
    9) "flags"
   10) "master"
   11) "link-pending-commands"
   12) "0"
   13) "link-refcount"
   14) "1"
   15) "last-ping-sent"
   16) "0"
   17) "last-ok-ping-reply"
   18) "440"
   19) "last-ping-reply"
   20) "440"
   21) "down-after-milliseconds"
   22) "10000"
   23) "info-refresh"
   24) "9021"
   25) "role-reported"
   26) "master"
   27) "role-reported-time"
   28) "956691745"
   29) "config-epoch"
   30) "51"
   31) "num-slaves"
   32) "2"
   33) "num-other-sentinels"
   34) "2"
   35) "quorum"
   36) "2"
   37) "failover-timeout"
   38) "60000"
   39) "parallel-syncs"
   40) "1"
```

1. Failover the master to one of the replicas:
```shell
/opt/gitlab/embedded/bin/redis-cli -p 26379 SENTINEL failover CLUSTER_NAME
```
CLUSTER_NAME is one of `gprd-redis` (main persistent cluster), `gprd-redis-cache` (primary transient cache), `gprd-redis-sidekiq` (sidekiq specific persistent cluster)

## Replication flapping

### Possible causes ###

- A redis failover causes the slaves to sync from the master, that might be constrained by the client-output-buffer-limit.
- If Redis is frequently failing over, it may be worth checking the Redis Sentinel logs (`/var/log/gitlab/sentinel/current`).
- Possible causes include:
    * Host network connectivity
    * Redis is being killed by the OOMKiller
    * A very high latency command (for example `keys *` or `debug sleep 60`) is preventing Redis from processing commands
    * Redis is unable to write the RDB snapshot, leading to the instance becoming read-only (check `/opt/gitlab/embedded/bin/redis-cli config get dir`,  `df -h /var/opt/gitlab/redis` for space)

### Possible fixes ###

Temporarily disable the `client-output-buffer-limit` on the new master.

```
REDISCLI_AUTH=$(sudo grep ^masterauth /var/opt/gitlab/redis/redis.conf|cut -d\" -f2)
/opt/gitlab/embedded/bin/redis-cli config set client-output-buffer-limit "slave 0 0 0"
```

Once the cluster is stable again, revert the change by setting the value, to the value from the configuration file. (`/var/opt/gitlab/redis/redis.conf`)
You'll need to convert any non-bytes number into bytes to apply it on the console (i.e. 4gb = 4*1024*1024*1024 = 4294967296)

Thus for a line in the config like this
```
client-output-buffer-limit slave 4gb 4gb 0
```
You need to execute this:
```
REDISCLI_AUTH=$(sudo grep ^masterauth /var/opt/gitlab/redis/redis.conf|cut -d\" -f2)
/opt/gitlab/embedded/bin/redis-cli config set client-output-buffer-limit "slave 4294967296 4294967296 0"
```

## Redis is down

### Start Redis ###

`gitlab-ctl start redis`

## Failed to collect Redis metrics

### Symptoms

- You see alerts like `FailedToCollectRedisMetrics`.
- Redis metrics are unavailable

### Possible checks

### Solution

If everything looks ok, it might be that the instance made a full resync from
master. During that time the redis_exporter fails to collect metrics from
redis. Check `/var/log/gitlab/redis/current` for `MASTER <-> SLAVE sync`
events during the time of the alert.


If either of the `redis` or `sentinel` services is down, restart it with

`gitlab-ctl restart redis`

or

`gitlab-ctl restart sentinel`.

Else check for possible issues in `/var/log/gitlab/redis/current` (e.g. resync
from master) and see [redis_replication.md].

# Miscellaneous

## BigKeys analysis

Per https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/360 there may be a script that runs periodically (hourly by default) on a redis replica, to collect 'bigkeys' output and store it for later analysis.  

The frequency can be controlled with the chef attribute `redis_analysis.bigkeys.timer_on_calendar`, being a systemd time spec.  You probably do not want to run it more than once an hour (it's intended for broad-brush data collection, not fine-grained), although other than considering how long it takes to run and avoiding overlap there's not actual constraint on that.  

If it needs to be stopped for some reason (it is running badly, is causing undue load, or other unexpected effects) it can be
1. Stopped if currently running, with `sudo systemctl stop redis-bigkeys-extract.service'
1. Prevented from running again (until chef next runs) with `sudo systemctl stop redis-bigkeys-extract.timer`
1. Turned off by chef by setting the attribute 'redis_analysis.bigkeys.timer_enabled` to false, e.g. in a role

# References #

- https://blog.octo.com/en/what-redis-deployment-do-you-need/
- https://lzone.de/cheat-sheet/Redis
- https://tech.trivago.com/2017/01/25/learn-redis-the-hard-way-in-production/
- https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/80
- https://gitlab.com/gitlab-com/gl-infra/scalability/issues/49
- https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/7199
- https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9414

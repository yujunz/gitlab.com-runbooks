# Redis latency

## Diagnosing Redis Latency Issues

## Contention

The [`redis_instantaneous_ops_per_sec`](https://prometheus.gprd.gitlab.net/graph?g0.range_input=1h&g0.expr=redis_instantaneous_ops_per_sec&g0.tab=0) may indicate if Redis is experiencing a very high RPS, leading to queueing requests.

## Check the slow log

The slowlog records slow Redis queries. Because Redis is single-threaded but the application relies on Redis throughput to be very high, latency spikes can be detrimental to the operation of the entire application.

The slowlog will record any commands that take more than 10000 microseconds to complete (or 10ms).

You can double-check the threshold using the redis commands `CONFIG GET slowlog-log-slower-than`.

In order to obtain entries from the slow log, use [`SLOWLOG GET n`](https://redis.io/commands/slowlog).

```shell
$ REDIS_MASTER_AUTH=$(sudo grep ^masterauth /var/opt/gitlab/redis/redis.conf|cut -d\" -f2)
$ /opt/gitlab/embedded/bin/redis-cli -a $REDIS_MASTER_AUTH SLOWLOG GET 10
1) 1) (integer) 5100            # A unique progressive identifier for every slow log entry.
   2) (integer) 1561019091      # The unix timestamp at which the logged command was processed.
   3) (integer) 21390           # The amount of time needed for its execution, in microseconds.
   4) 1) "del"                  # The array composing the arguments of the command.
      2) "cache:gitlab:242234:8213877:Ci::CompareTestReportsService"
```

To convert the timestamp, use `date -d @1561019091`.

### Monitoring the rate of change in the slowlog

A useful metric for monitoring potential slow-downs in Redis is measuring the rate of change in the `redis_slowlog_last_id`.

This can be done by plotting (`changes(redis_slowlog_last_id[1h])`](https://prometheus.gprd.gitlab.net/graph?g0.range_input=1d&g0.expr=changes(redis_slowlog_last_id%5B1h%5D)&g0.tab=0).

## Using `LATENCY DOCTOR`

Redis provides a latency diagnotic tool.

You may need to enable it with `CONFIG SET latency-monitor-threshold 100`.

From https://redis.io/topics/latency-monitor:

> By default monitoring is disabled (threshold set to 0), even if the actual cost of latency monitoring is near zero. However while the memory requirements of latency monitoring are very small, there is no good reason to raise the baseline memory usage of a Redis instance that is working well.

```shell
$ REDIS_MASTER_AUTH=$(sudo grep ^masterauth /var/opt/gitlab/redis/redis.conf|cut -d\" -f2)
$ /opt/gitlab/embedded/bin/redis-cli -a $REDIS_MASTER_AUTH CONFIG SET latency-monitor-threshold 100
$ /opt/gitlab/embedded/bin/redis-cli -a $REDIS_MASTER_AUTH LATENCY DOCTOR
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

$ /opt/gitlab/embedded/bin/redis-cli -a $REDIS_MASTER_AUTH CONFIG SET latency-monitor-threshold 0
```

# Redis troubleshooting

## First and foremost

*Don't Panic*

## Replication issues

See [redis_replication.md].

## Flapping

See [redis_flapping.md].


## Failed to collect Redis metrics

### Symptoms

You see alerts like `FailedToCollectRedisMetrics`.

### Possible checks

#### Checks Using Prometheus

https://thanos-query.ops.gitlab.net/graph?g0.range_input=1w&g0.expr=redis_up%20%3C%201&g0.tab=0

#### Check on host

* is redis up?
  * `gitlab-ctl status`
* can we dial redis?
  * `telnet localhost 6379`
* can we talk to redis via `redis-cli`?

```
REDIS_MASTER_AUTH=$(sudo grep ^masterauth /var/opt/gitlab/redis/redis.conf|cut -d\" -f2)
/opt/gitlab/embedded/bin/redis-cli -a $REDIS_MASTER_AUTH info
```

If everything looks ok, it might be that the instance made a full resync from
master. During that time the redis_exporter fails to collect metrics from
redis. Check `/var/log/gitlab/redis/current` for `MASTER <-> SLAVE sync`
events during the time of the alert.

### Solution

If either of the `redis` or `sentinel` services is down, restart it with

`gitlab-ctl restart redis`

or

`gitlab-ctl restart sentinel`.

Else check for possible issues in `/var/log/gitlab/redis/current` (e.g. resync
from master) and see [redis_replication.md].


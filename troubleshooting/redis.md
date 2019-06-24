# Redis troubleshooting

## First and foremost

*Don't Panic*

## Replication issues

See [redis_replication.md].


## Redis Process Down

### Symptoms

You see alerts like `RedisProcessDown`

### Possible checks

#### Checks Using Prometheus

https://thanos-query.ops.gitlab.net/graph?g0.range_input=1w&g0.expr=redis_up%20%3C%201&g0.tab=0

#### Check on host

`gitlab-ctl status`

### Solution

If either of the `redis` or `sentinel` services is down, restart it with

`gitlab-ctl restart redis`

or

`gitlab-ctl restart sentinel`.


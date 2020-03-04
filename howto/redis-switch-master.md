## Redis Switch Master

### General overview

The redis log has a switch master event.

This page needs more detail on what to do in this instance

### How to manually switch masters

On one of the nodes running the redis sentinel (varies by cluster; redis + redis-sidekiq run sentinel on the main redis nodes, redis-cache has its own set of sentinel servers, and this may change in future):

```
/opt/gitlab/embedded/bin/redis-cli -p 26379 SENTINEL failover MASTER_NAME
```

`MASTER_NAME` is one of `gprd-redis` (main persistent cluster), `gprd-redis-cache` (primary transient cache), `gprd-redis-sidekiq` (sidekiq specific persistent cluster)

The current master can be determined with `/opt/gitlab/embedded/bin/redis-cli -p 26379 sentinel masters` on one of the sentinel nodes.  The 4th output item is the IP address of the current master node.

This should have no visible negative impact on the GitLab application

### Check the status (master/slave) of a redis node directly

```
REDIS_MASTER_AUTH=$(sudo grep ^masterauth /var/opt/gitlab/redis/redis.conf|cut -d'"' -f2)
/opt/gitlab/embedded/bin/redis-cli -a $REDIS_MASTER_AUTH --csv ROLE
```

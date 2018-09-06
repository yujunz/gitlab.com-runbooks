# Redis replication is lagging or has stopped

## First and foremost

*Don't Panic*

## Symptoms

You see alerts like

```
@channel redis[34567].cluster.gitlab.com service Redis_replication_lag is CRITICAL
```

## Possible checks

### Checks Using Prometheus

#### Redis Primaries

List the Redis primaries using:

* [`redis_master_repl_offset > 0`](https://prometheus.gitlab.com/graph?g0.range_input=1h&g0.expr=redis_master_repl_offset%20%3E%200%20&g0.tab=1)

#### Redis Secondaries

List the Redis secondaries using:

* [`redis_slave_info`](https://prometheus.gitlab.com/graph?g0.range_input=1h&g0.expr=redis_slave_info&g0.tab=1)

#### Redis Replication Lag

Replication lag indicates that the Redis secondaries are struggling to keep up with the changes on the primary. This may be due to the rate of changes on the primary being too high, or the secondaries being under too much load to keep up.

Replication lag is measured in bytes in the replication stream.

https://dashboards.gitlab.net/dashboard/db/andrew-redis?panelId=13&fullscreen&orgId=1

#### Redis Replication Events

* Check the Redis Replication Events dashboard to see if Redis is frequently failing over. This may indicate replication issues. https://dashboards.gitlab.net/dashboard/db/andrew-redis?panelId=14&fullscreen&orgId=1

### Redis Sentinel

Redis Sentinel provides an pointer for compatible clients to the current Redis primary. Clients will query Sentinel and then connect directly to the primary Redis (in other words, Redis sentinel does not proxy requests).

Additionally, Redis Sentinel will reconfigure Redis instances as primary or secondaries, depending on the Sentinel clusters quorum.

Sentinel is configured via `gitlab.rb`:

```shell
$ sudo grep redis_sentinels /etc/gitlab/gitlab.rb
gitlab_rails['redis_sentinels'] = [{"host"=>"10.66.2.101", "port"=>26379}, {"host"=>"10.66.2.102", "port"=>26379}, {"host"=>"10.66.2.103", "port"=>26379}]
```

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

* ssh into the redis host which generated the alert and check the actual replication status

```shell
root@redis7:~# REDIS_MASTER_AUTH=$(sudo grep ^masterauth /var/opt/gitlab/redis/redis.conf|cut -d\" -f2)
root@redis7:~# /opt/gitlab/embedded/bin/redis-cli -a $REDIS_MASTER_AUTH
127.0.0.1:6379> info replication
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

### Why is Redis Failing Over?

* If Redis is frequently failing over, it may be worth checking the Redis Sentinel logs (`/var/log/gitlab/sentinel/current`).
* Possible causes include
    * Host network connectivity
    * Redis is being killed by the OOMKiller
    * A very high latency command (for example `keys *` or `debug sleep 60`) is preventing Redis from processing commands
    * Redis is unable to write the RDB snapshot, leading to the instance becoming read-only (check `/opt/gitlab/embedded/bin/redis-cli -a $REDIS_MASTER_AUTH config get dir`,  `df -h /var/opt/gitlab/redis` for space)

## Resolution

* Just wait, every slave should automatically restart it's replication when it drops out
* If it takes longer then expected check /var/log/gitlab/redis/current on the mailfunctioning slave for any indications why it won't restart replication

## Helpful Resources

* https://redis.io/topics/replication
* https://redis.io/topics/sentinel
* https://redislabs.com/blog/top-redis-headaches-for-devops-replication-buffer/
* https://redislabs.com/blog/top-redis-headaches-for-devops-replication-timeouts/
* https://redislabs.com/blog/top-redis-headaches-for-devops-client-buffers/



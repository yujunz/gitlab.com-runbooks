# Blocking individual IPs using Redis and Rack Attack

## First and foremost

* *Don't Panic*
* Be very careful with Redis. There are commands that can be run from the command line that lock it up entirely without warning.

## Background

Redis is the session store and short-term cache. It's used by the Rack Attack module to perform temporary bans and throttling
against specific IP addresses. It should not be used to ban netblocks.

## How do I

### Connect to Redis

Connecting to Redis is done via the `redis-cli` command line program included with Omnibus. Replace `10.0.0.1`
with the IP of a Redis node.

```
worker$ /opt/gitlab/embedded/bin/redis-cli -h 10.0.0.1
10.0.0.1:6379> auth <password>
10.0.0.1:6379>
```

### Find the Redis master node

Writes to Redis can only be performed from the Redis master node. To determine which
host is the master node you can query the currently connected node:

```
worker$ /opt/gitlab/embedded/bin/redis-cli -h 10.0.0.1
10.0.0.1:6379> auth <password>
10.0.0.1:6379> info replication
# Replication
role:slave
master_host:10.0.0.2
master_port:6379
master_link_status:up
master_last_io_seconds_ago:0
master_sync_in_progress:0
slave_repl_offset:xxx
slave_priority:100
slave_read_only:1
connected_slaves:0
master_repl_offset:xxx
repl_backlog_active:0
repl_backlog_size:xxx
repl_backlog_first_byte_offset:xxx
repl_backlog_histlen:xxx
```

Or if you're already connected to the master:

```
# Replication
role:master
connected_slaves:4
slave0:ip=xxx,port=6379,state=online,offset=xxx,lag=1
slave1:ip=xxx,port=6379,state=online,offset=xxx,lag=1
slave2:ip=xxx,port=6379,state=online,offset=xxx,lag=1
slave3:ip=xxx,port=6379,state=online,offset=xxx,lag=1
master_repl_offset:xxx
repl_backlog_active:1
repl_backlog_size:xxx
repl_backlog_first_byte_offset:xxx
repl_backlog_histlen:xxx
```

Note that the Redis master node can move _while you are connected_ to it. So you
may find that you get an error when writing a new key saying you cannot write to
a slave node. When this happens repeat the above process to find the new master.

Redis-cli will also drop authentication frequently, forcing you to re-auth.

### Ban a single IP

Rack Attack supports blocking via two methods: throttling and blacklisting. In this
case we are only concerned with blacklisting a single IP `192.168.0.1`.

```
worker$ /opt/gitlab/embedded/bin/redis-cli -h 10.0.0.1
10.0.0.1:6379> auth <password>
10.0.0.1:6379> setex cache:gitlab:rack::attack:allow2ban:ban:192.168.0.1 86400 "1"
```

This will ban the IP for 24 hours (86400 seconds) by storing the value "1" in the listed
key. Since this isn't a preferred method to blacklist a host it's best not to use a longer TTL.
`setex` is equivalent to `set <keyname> <keyvalue> ex <expiry_period_in_s>`

### Get currently banned IPs

DO NOT use `KEYS` for searching for keys on production, this will freeze the redis server for tens of seconds if not minutes.
Instead use:
```
/opt/gitlab/embedded/bin/redis-cli -a $REDIS_MASTER_AUTH -h 127.0.0.1 -p 6379 --scan --pattern 'cache:gitlab:rack::attack:allow2ban:ban:*'
```

### Should a block need to be removed

Removing blocks is as simple as removing the key in Redis.

```
worker$ /opt/gitlab/embedded/bin/redis-cli -h 10.0.0.1
10.0.0.1:6379> auth <password>
10.0.0.1:6379> del cache:gitlab:rack::attack:allow2ban:ban:192.168.0.1
```

### Rack attack redis data structure

Banned ip addresses are stored as names of keys.
These keys are of type string.
Storing the value of "1" will block the ip address.
The namespaces used for storing those keys is `cache:gitlab:rack::attack:allow2ban:ban`

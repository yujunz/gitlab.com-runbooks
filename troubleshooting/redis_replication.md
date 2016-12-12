# Redis replication is lagging or has stopped

## First and foremost

*Don't Panic*

## Symptoms

You see alerts like

```
@channel redis[34567].cluster.gitlab.com service Redis_replication_lag is CRITICAL
```

## Possible checks

* ssh into the redis host which generated the alert and check the actual replication status

```
root@redis7:~# /opt/gitlab/embedded/bin/redis-cli 
127.0.0.1:6379> auth PASSWORD
OK
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

## Resolution

* Just wait, every slave should automatically restart it's replication when it drops out
* If it takes longer then expected check /var/log/gitlab/redis/current on the mailfunctioning slave for any indications why it won't restart replication




# Redis replication is lagging or has stopped

## First and foremost

*Don't Panic*

This is not a critical emergency, it's important, yes, but not critical.

## Symptoms

You see alerts like

```
@channel redis[34].cluster.gitlab.com service Redis_replication_lag is CRITICAL
```

## Possible checks

* ssh into the redis host and check that it is the actual replication slave

```
# sudo crm status
Last updated: Sat Jun 11 16:14:07 2016
Last change: Wed Apr  6 06:37:16 2016 via crmd on redis3.cluster.gitlab.com
Stack: corosync
Current DC: redis3.cluster.gitlab.com (167837722) - partition with quorum
Version: 1.1.10-42f2063
2 Nodes configured
1 Resources configured


Online: [ redis3.cluster.gitlab.com redis4.cluster.gitlab.com ]

 gitlab_redis (ocf::pacemaker:gitlab_redis):  Started redis3.cluster.gitlab.com
```

In this case the master is redis3 => `gitlab_redis (ocf::pacemaker:gitlab_redis):  Started redis3.cluster.gitlab.com`

## Resolution

* Get the ip of the redis master server
* Get redis password with `grep requirepass /var/opt/gitlab/redis/redis.conf`
* Turn into root
* Run `/root/gitlab_redis_recovery.sh` and provide the required info




# Managing pacemaker and corosync

## Force a failover on redis

```
redis3# crm status
Last updated: Fri Jul 15 12:57:18 2016
Last change: Fri Jul 15 11:24:46 2016 via cibadmin on redis4.cluster.gitlab.com
Stack: corosync
Current DC: redis3.cluster.gitlab.com (167837722) - partition with quorum
Version: 1.1.10-42f2063
2 Nodes configured
1 Resources configured


Online: [ redis3.cluster.gitlab.com redis4.cluster.gitlab.com ]

 gitlab_redis	(ocf::pacemaker:gitlab_redis):	Started redis3.cluster.gitlab.com
```
As you can see gitlab_redis is running on redis3 so login on redis4 and execute the failover command:
```
redis4# /root/gitlab_redis_failover.sh 
```

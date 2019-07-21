## Building a new redis cluster and starting replication

From time to time you may have to build (or rebuild) a redis cluster.  While the omnibus documentation (https://docs.gitlab.com/ee/administration/high_availability/redis.html) says everything should start replicating by magic, it doesn't in our builds because we touch /etc/gitlab/skip-autoreconfigure on redis nodes, so that restarts during upgrades can be done in a more controlled fashion across multiple nodes.

So, after building the nodes, there are some manual steps to take:

1. On all nodes, `sudo gitlab-ctl reconfigure`
  * This will reconfigure/start up redis, but not sentinel
1. On all nodes, `sudo gitlab-ctl start sentinel`
  * Not sure why, but it's minor
1. On the replicas, start replicating from the master:
  1. REDIS_MASTER_AUTH=$(sudo grep ^masterauth /var/opt/gitlab/redis/redis.conf|cut -d\" -f2)
  1. /opt/gitlab/embedded/bin/redis-cli -a $REDIS_MASTER_AUTH
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

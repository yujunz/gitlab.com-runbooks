# Redis flapping

## Possible causes

 - A redis failover causes the slaves to sync from the master, that might be constrained by the client-output-buffer-limit.

## Possible fixes

Temporarily disable the `client-output-buffer-limit` on the new master.

```
REDIS_MASTER_AUTH=$(sudo grep ^masterauth /var/opt/gitlab/redis/redis.conf|cut -d\" -f2)
/opt/gitlab/embedded/bin/redis-cli -a $REDIS_MASTER_AUTH config set client-output-buffer-limit "slave 0 0 0"
```

Once the cluster is stable again, revert the change by setting the value, to the value from the configuration file. (`/var/opt/gitlab/redis/redis.conf`)  
You'll need to convert any non-bytes number into bytes to apply it on the console (i.e. 4gb = 4*1024*1024*1024 = 4294967296)

Thus for a line in the config like this
```
client-output-buffer-limit slave 4gb 4gb 0
```
You need to execute this:
```
REDIS_MASTER_AUTH=$(sudo grep ^masterauth /var/opt/gitlab/redis/redis.conf|cut -d\" -f2)
/opt/gitlab/embedded/bin/redis-cli -a $REDIS_MASTER_AUTH config set client-output-buffer-limit "slave 4294967296 4294967296 0"
```

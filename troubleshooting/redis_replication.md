# Redis replication lag

## Symptoms

when you see messages like 

```
@channel redis[34].cluster.gitlab.com service Redis_replication_lag is CRITICAL
```

## Resolution

  * Get ip of redis3.cluster.gitlab.com
  * Get password by `grep requirepass /var/opt/gitlab/redis/redis.conf`
  * Run `/root/gitlab_redis_recovery.sh` and provided needed info

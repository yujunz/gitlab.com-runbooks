# Redis replication lag

## Symptoms

## Resolution

* Run script on redis4.cluster.gitlab.com
  * `/root/gitlab_redis_recovery.sh`
  * you will need to provide following information
     * ip of redis3.cluster.gitlab.com
     * and password obtained by `grep requirepass /var/opt/gitlab/redis/redis.conf`

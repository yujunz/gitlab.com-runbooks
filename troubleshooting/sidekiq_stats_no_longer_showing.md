Sidekiq stats are collected by [gitlab-monitor](https://gitlab.com/gitlab-org/gitlab-monitor/blob/fdad76bdff3698111744c4bfbc129c57d99355b7/lib/gitlab_monitor/sidekiq.rb) by talking to Redis, and scraped by Prometheus.
If you see no stats in the [Sidekiq dashboard](http://dashboards.gitlab.net/dashboard/db/sidekiq-stats) then something could be wrong with these three components.

## Symptoms

* A warning message in prometheus-alerts
* Total Running Jobs or Running Jobs panels are showing flat lines

## 1. Identify the Redis master

On any of the redis nodes `redis0X.db.gitlab.com` run:

```
/opt/gitlab/embedded/bin/redis-cli -p 26379
```

then type this in Redis console:

```
sentinel master gitlab-redis
```

you should see output like this:

```
 1) "name"
 2) "gitlab-redis"
 3) "ip"
 4) "10.66.2.103"
 5) "port"
 6) "6379"
 ```

the master is the node with private IP of `10.66.2.103`, to get the actual node run the following on your machine:

 ```
knife ssh 'roles:gitlab-base-db-redis' "ifconfig | grep '10.66.2.103'"
```

the first column of the output is IP you should ssh to.

## 2. Verify gitlab-monitor service is running

On the master node, run:

```
sudo sv status gitlab-monitor
```

which ideally should return something like this:

```
run: gitlab-monitor: (pid 1271) 19889s; run: log: (pid 1267) 19889s
```

if not, run:

```
sudo sv start gitlab-monitor
```

## 3. Verify gitlab-monitor is collecting metrics

On the master node, run:

```
curl http://localhost:4567/sidekiq
```

it should return something like:

```
sidekiq_queue_size{name="system_hook"} 0
sidekiq_queue_size{name="update_merge_requests"} 0
sidekiq_queue_latency{name="admin_emails"} 0
sidekiq_queue_latency{name="archive_repo"} 0
<snip>
```

If it returned some Ruby errors, open an issue in gitlab-monitor project.

## 4. Verfiy Prometheus is scraping the master node

Login to the prometheus node, run:

```
less /opt/prometheus/prometheus/inventory/gitlab-monitor-redis.yml
```

it should have multiple entries for the redis nodes we have, make sure it got an entry
for with the private IP you obtained from step 1. If not, then make sure the `prometheus-server` Chef role
is configured to scrape both roles of `gitlab-cluster-redis-master` and `gitlab-cluster-redis-slave` (more on that in
[gitlab-prometheus README](https://gitlab.com/gitlab-cookbooks/gitlab-prometheus)), then run:

```
sudo chef-client
```

# Sidekiq Queue Out of Control

When the filesystem or database has major issues, it is possible
for the sidekiq queues to grow out of control. If the queues don't appear
to be getting any better after resolving other issues, please follow
the resolution below.

## Data Gathering

Run the following command in order to get Sidekiq to output debug info to the log

```
kill -TTIN <sidekiq_pid>
```

Check in `/var/log/gitlab/sidekiq/current` for the output. Check for blocking 
queries when backtraces above show that many threads are stuck in the database adapter.

If `kill -TTIN` fails to work due to high CPU usage, gather statistics from `perf`. 

```
sudo perf record -p <sidekiq_pid>
```

Let that run for around 30 seconds and then check the report `sudo perf report`

## Resolution

The best way to deal with the large queue is to spin up more sidekiq worker processes 
with fewer threads that specifically deal with troublesome queues. Often, this is the 
`pipelines` and `project_cache` queues.

The command we use to do that is:

```
sudo -u git PATH=/opt/gitlab/bin:/opt/gitlab/embedded/bin:/bin:/usr/bin LD_PRELOAD=/opt/gitlab/embedded/lib/libjemalloc.so BUNDLE_GEMFILE=/opt/gitlab/embedded/service/gitlab-rails/Gemfile /opt/gitlab/embedded/bin/bundle exec sidekiq -q project_cache -t 2 -c 1 -r /opt/gitlab/embedded/service/gitlab-rails -e production
```

In the most recent incident (gitlab-com/infrastructure#677), we spun up 2 threads on all
of the workers, resulting in around 25 processes across the fleet.

## References

https://gitlab.com/gitlab-com/infrastructure/issues/677
https://gitlab.com/gitlab-com/infrastructure/issues/606
https://gitlab.com/gitlab-com/infrastructure/issues/584
https://docs.gitlab.com/ee/administration/troubleshooting/sidekiq.html

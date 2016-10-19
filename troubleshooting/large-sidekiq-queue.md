# Sidekiq Queue Out of Control

When the filesystem or database has major issues, it is possible
for the sidekiq queues to grow out of control. If the queues don't appear
to be getting any better after resolving other issues, please follow
the resolution below.

## Resolution

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

If nothing else works, try restarting Sidekiq with `gitlab-ctl sidekiq restart`. If it 
does not respond to that, forcibly restart them.

```
sudo gitlab-ctl kill sidekiq
```

## References

https://gitlab.com/gitlab-com/infrastructure/issues/606
https://gitlab.com/gitlab-com/infrastructure/issues/584
https://docs.gitlab.com/ee/administration/troubleshooting/sidekiq.html

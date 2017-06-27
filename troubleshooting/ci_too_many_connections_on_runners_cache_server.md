# Too many connections on Runner's cache server

## Symptoms

Jobs are being executed longer than usual. In most cases they seem to hang on restoring or archiving the cache.

## Possible checks

1. Check the `Established connections` [graph for cache servers][cache server connections graph].

    Look for connections growth over 500, that is present for a longer time (more than 10 minutes). There may exists
    even bigger spikes that are going down quickly - these are expected. But if number of connections is going over
    500 and it exists like that for more than 10 minutes then most probably it will be not able to self-heal.

    ![Too many connections to cache server](../img/ci/cache_server_too_many_connections.png)

1. Check the [`Jobs running on runners owned by GitLab Inc. (by Runner's stage)` graph][jobs by runner's stage graph].

    If there is any problem with cache server then most probably you will see that `archive_cache` and/or
    `restore_cache` stages are taking most of the Runner's compute power. While looking at this graph you can assume
    that proportions between number of stages present on Runners are proportional to the average time that is taken by
    each stage. Cache server problems may make `archive_cache` and/or `restore_cache` to take longer than usual.

    ![Runners by stage - cache server problem](../img/ci/runners_by_stage_problem_with_cache.png)

1. Login to chosen cache server and check `netstat` output, e.g.:

    ```bash
    $ ssh runners-cache-5.gitlab.com-
    user@runners-cache-5:~$ $ netstat -anept | grep tcp | awk '{print $6}' | sort | uniq -c | sort -g
    (Not all processes could be identified, non-owned process info
     will not be shown, you would have to be root to see it all.)
          6 ESTABLISHED
         11 LISTEN
         56 TIME_WAIT
    ```

    It's normal when the number of `ESTABLISHED` and `TIME_WAIT` connections is less than 200-300 (and most time there
    will be more `TIME_WAIT` connections than `ESTABLISHED` ones). The problem is when the number of these connections
    growths over the limit 200-300 for a longer period - that's why the alert was set for `over 500 in 10 minutes`.

    Most time, when the problem exists, there will be a big number of connections in `TIME_WAIT`, `CLOSE_WAIT` or
    `FIN_WAIT2` states.

## Resolution

Stop nginx, restart present containers and start nginx again:

```bash
sudo systemctl stop nginx
(sudo docker ps | grep -q registry && sudo docker restart registry) || echo "Registry is not running. Skipping."
(sudo docker ps | grep -q minio_minio && sudo docker restart minio_minio) || echo "Minio is not running. Skipping."
sudo systemctl start nginx
```

Above commands should resolve the problem immediately. Both `netstat` and [cache server connections graph] should
show the drop of the number of connections. After a while the change should also be visible on [jobs by runner's
stage graph].

In jobs that at this moment were in the `archive_cache` or `restore_cache` stage, the current cache operation may be
interrupted and may fail but this should not fail the whole job (just make it slower if cache was not restored).

[cache server connections graph]:https://performance.gitlab.net/dashboard/db/ci?orgId=1&refresh=5m&from=now-24h&to=now&panelId=56&fullscreen
[jobs by runner's stage graph]:https://performance.gitlab.net/dashboard/db/ci?refresh=5m&orgId=1&from=now-24h&to=now&panelId=6&fullscreen


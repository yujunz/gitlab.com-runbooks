# Praefect replication is lagging or has stopped

## Symptoms

* Alert: "The `praefect` service (`main` stage) has a apdex score (latency) below SLO"

## Checks

### Replication queue in Postgresql

[Connect to the Praefect database](docs/praefect/praefect-database.md) and query
the queue table for replication jobs in progress:

```
praefect_production=> select * from replication_queue where state = 'in_progress';
   id    |    state    |         created_at         |         updated_at         | attempt |                                                       lock_id                                                       |
                                                                  job                                                                                                                                   |               meta
---------+-------------+----------------------------+----------------------------+---------+---------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------
 1947782 | in_progress | 2020-07-23 14:37:45.855009 | 2020-07-23 14:38:54.381454 |       2 | praefect-file01|file-praefect-02|@hashed/fa/53/fa539965395b8382145f8370b34eab249cf610d2d6f2943c95b9b9d08a63d4a3.git | {"change": "update", "params": null, "relative_path": "@hashed/f
a/53/fa539965395b8382145f8370b34eab249cf610d2d6f2943c95b9b9d08a63d4a3.git", "virtual_storage": "praefect-file01", "source_node_storage": "file-praefect-01", "target_node_storage": "file-praefect-02"} | {"correlation_id": "yD7XURUnUD4"}
(2 rows)
```

As replication is a sequential process, in case processing of a single job takes
too much time all other jobs will wait until it completes before they get
started. To verify if the job is actually processed by Praefect you should check
the state of the replication_queue_job_lock table:

```
praefect_production=> select * from replication_queue_job_lock;
 job_id  |                                                       lock_id                                                       |        triggered_at
---------+---------------------------------------------------------------------------------------------------------------------+----------------------------
 1947782 | praefect-file01|file-praefect-02|@hashed/fa/53/fa539965395b8382145f8370b34eab249cf610d2d6f2943c95b9b9d08a63d4a3.git | 2020-07-23 18:11:54.865618
```

The lock is refreshed every 5 seconds (see column `triggered_at`). The job will
be considered stale and moved into 'failed' or 'dead' state after 30 sec without
update and the corresponding row will be removed from the
`replication_queue_job_lock` table.

### Replication delay metrics

Check [the `gitaly_praefect_replication_delay_count` metric on
thanos](https://thanos-query.ops.gitlab.net/new/graph?g0.expr=gitaly_praefect_replication_delay_count%7Benv%3D%22gprd%22%7D&g0.tab=0&g0.stacked=0&g0.range_input=2w).
A sawtooth graph (as below) is ideal, with replication delay growing gradually
until it is brought down by replication jobs being executed.

![](./img/praefect-replication-delay.png)

If the graph is trending upwards it points to replication jobs being created
but not being processed.

If the graph is linear or data is missing it points to the replication manager
not working entirely.

### Logs

Check the [praefect logs, filtering by `json.component:
replication_manager`](https://log.gprd.gitlab.net/goto/643ce861af0f87d7003c47ec998c75b0)
for relevant error messages. If you see no logs, the replication manager is not
processing any jobs.

If the replication manager appears to not be processing any jobs, try restarting
the Praefect process with `sudo gitlab-ctl restart praefect`. Make sure to
perform the restart on each Praefect node one by one (as opposed to all at once)
to diminish the impact on production traffic.

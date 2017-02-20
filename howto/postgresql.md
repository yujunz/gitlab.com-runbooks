# Postgresql

## Find out which table a given toast belongs to

Run this query

```
select n.nspname, c.relname
from pg_class c
inner join pg_namespace n on c.relnamespace = n.oid
where reltoastrelid = (
    select oid
    from pg_class
    where relname = 'pg_toast_16518'
    and relnamespace = (SELECT n2.oid FROM pg_namespace n2 WHERE n2.nspname = 'pg_toast') );

 nspname |       relname
---------+---------------------
 public  | merge_request_diffs
(1 row)
```

## Get a list of all active queries

```
SELECT pid, state, age(clock_timestamp(), query_start) as duration, query
FROM pg_stat_activity
WHERE query != '<IDLE>' AND query NOT ILIKE '%pg_stat_activity%' AND state != 'idle'
ORDER BY age(clock_timestamp(), query_start) DESC;
```

## Get a list of slow queries (more than 1 second)

```
SELECT pid, state, age(clock_timestamp(), query_start) as duration, query
FROM pg_stat_activity
WHERE query != '<IDLE>' AND query NOT ILIKE '%pg_stat_activity%' AND state != 'idle' AND age(clock_timestamp(), query_start) > '00:01:00'
ORDER BY age(clock_timestamp(), query_start) DESC;
```

## Get a list of queries that are waiting

```
SELECT pid, query, age(clock_timestamp(), query_start) AS query_duration
FROM pg_catalog.pg_stat_activity WHERE  waiting
ORDER BY age(clock_timestamp(), query_start) DESC;
```

## Get a list of locked queries with the query that is blocking it

```
SELECT blockingl.relation::regclass,
  blockeda.pid AS blocked_pid, blockeda.query as blocked_query,
  blockedl.mode as blocked_mode,
  age(clock_timestamp(), blockeda.query_start) as blocked_query_duration,
  blockinga.pid AS blocking_pid, blockinga.query as blocking_query,
  blockingl.mode as blocking_mode,
  age(clock_timestamp(), blockinga.query_start) as blocking_query_duration
FROM pg_catalog.pg_locks blockedl
JOIN pg_stat_activity blockeda ON blockedl.pid = blockeda.pid
JOIN pg_catalog.pg_locks blockingl ON(blockingl.relation=blockedl.relation
  AND blockingl.locktype=blockedl.locktype AND blockedl.pid != blockingl.pid)
JOIN pg_stat_activity blockinga ON blockingl.pid = blockinga.pid
WHERE NOT blockedl.granted;
```

## Run pgbadger in the primary database server

* sudo up
* `pgbadger | /usr/bin/pgbadger -o output.txt -`

## Triggering a Failover

To trigger a failover, run the following command on a **secondary**:

```bash
sudo -u gitlab-psql /opt/gitlab/embedded/bin/pg_ctl -D /var/opt/gitlab/postgresql/data promote
```

Alternatively you can also run the following:

```bash
sudo -u gitlab-psql touch /tmp/gitlab_replicator.trigger
```

This will promote the host these commands were executed on to the primary.

## Setting up Secondaries

Currently setting up a secondary requires some manual steps. First of all, make
sure that the replica has the following Chef roles assigned:

* `gitlab-cluster-base`
* `gitlab-cluster-db`
* `gitlab-cluster-db-replication`

These roles will take care of enabling hot stanby mode and the other settings
needed to get replication going.

Next, SSH into the secondary and run the following:

```bash
sudo gitlab-ctl start postgresql
sudo gitlab-ctl pg-upgrade
```

This is necessary because currently Omnibus defaults to PostgreSQL 9.2, and we
need 9.6.

Once this process is done you should run the following:

```bash
sudo /root/gitlab_pgsql_replicator.sh
```

This script will ask you to enter the primary's IP address (be sure to use the
internal/local IP) and the password to use for the recovery account. The
password can be found in the DevOps vault in 1Password, under the name "postgres
gitlab_replicator".

It may take a while for the above script to finish. As such it's best to run
this script using `tmux` or `screen` and check back in an hour or so.

Once done this script will generate a recovery file that PostgreSQL will use for
the replication process. This file can be found at
`/var/opt/gitlab/postgresql/data/recovery.conf`.

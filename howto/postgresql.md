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

A failover at the moment has numerous manual steps at the moment:

In general, we have an azure lb which executes a healthcheck on all the nodes in
its load balancing set. This healthcheck **ONLY** verifies that a port is open on
a host, regardless of the hosts, state. Currently, only one host is in the load 
balancing set: the current master (**db1**).

The failover proceedure is as follows:

1. stop postgres on primary (if the node is reachable)

2. promote secondary
run the following command on a **secondary**:

```bash
sudo -u gitlab-psql /opt/gitlab/embedded/bin/pg_ctl -D /var/opt/gitlab/postgresql/data promote
```

This will promote the host these commands were executed on to the primary.

3. update azure lb set
add the host which is now primary to the `Backend pools` for the load balancer.

* login to azure
* choose `all resources`
* search for `DBProdLB`
* click on `Backend pools`
* click on the `DBProd` pool
* click on `Add a target network IP configuration`
* From the `Target Virtual Machine` drop down, choose the new master
* click on the trash can to remove the old master

Note: so a machine can show up in the drop down, it has to be associated with the resource group and availibility set of the load balancer (in our case both are called `DBProd`).

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

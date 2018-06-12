<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Postgresql troubleshooting](#postgresql-troubleshooting)
    - [First and foremost](#first-and-foremost)
    - [Dashboards](#dashboards)
    - [Availability](#availability)
    - [Errors](#errors)
    - [Locks](#locks)
    - [Load](#load)
    - [Replication is lagging or has stopped](#replication-is-lagging-or-has-stopped)
        - [Symptoms](#symptoms)
        - [Possible checks](#possible-checks)
        - [Resolution](#resolution)
    - [Replication Slots](#replication-slots)
        - [Symptoms](#symptoms-1)
        - [Possible checks](#possible-checks-1)
        - [Resolution](#resolution-1)
    - [Tables with a large amount of dead tuples](#tables-with-a-large-amount-of-dead-tuples)
        - [Symptoms](#symptoms-2)
        - [Possible Checks](#possible-checks)
    - [Connections](#connections)
    - [PGBouncer Errors](#pgbouncer-errors)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Postgresql troubleshooting

## First and foremost

*Don't Panic*

## Dashboards

* https://performance.gitlab.net/dashboard/db/postgres-stats

* https://performance.gitlab.net/dashboard/db/postgres-tuple-statistics

* https://performance.gitlab.net/dashboard/db/postgres-queries

## Availability

Alerts that check for availability are XIDConsumptionTooLow
XLOGConsumptionTooLow and CommitRateTooLow. They all measure activity
on the database, not blackbox probes. Low values could indicate the
database is not responding or could indicate the application is having
difficulty connecting to the database.

They could also indicate the application is having its own problems
however ideally these thresholds should be set low enough that even a
minimually functional application would not trigger them.

Keep in mind that

Check:

* Postgres error logs (full disk or other I/O errors will normally not
  cause Postgres to shut down and may even allow read-only queries but
  will cause all read-write queries to generate errors).

* Check that you can connect to the database from a psql prompt.

* Check that the you can connect to the database from the Rails
  console.

* Check that you can make a database modification. Run `select
  txid_current()` is handy for this as it does require disk i/o to
  record the transaction. You could also try creating and dropping a
  dummy table.

* Check other triage dashboards such as the cpu load and I/O metrics
  on the database host in question.

## Errors

The RollbackRateTooHigh alert measures the ratio of rollbacks to
commits. It may not indicate a database problem since the errors may
be caused by an application issue.

* Check the database error logs (full disk, out of memory, no more
  file descriptors, or other resource starvation issues could cause
  all read-write transactions to fail while Postgres limps along
  completing read-only transactions for example).

* Check that the host in question is under normal load -- if the usage
  is extremely low due to replication lag or network issues then this
  may be a false positive.

Note that this alert can be fired for a replica or the primary.

## Locks

The PostgresTooManyRowExclusiveLocks alerts when there are a large
number of records in pg_locks for RowExclusiveLock.

This is often not indicative of a problem, especially if they're
caused by inserts rather than updates or deletes or if they're
short-lived. But updates or deletes that are not committed for a
significant amount of time can cause application issues.

Look for blocked queries or application latency.

Remediation can involved tracking down a rogue migration and killing
or pausing it.

## Load

DBHeavyLoad is triggered based on simple OS load measurement. Look for
a large number of active backends running poorly optimized queries
such as sorting large result sets or missing join clauses.

Don't forget to look for generic Unix problems that can cause high
load such as a broken disk (with processes getting stuck in disk-wait)
or some administrative task such as mlocate or similar forking many
child processes.

## Replication is lagging or has stopped

### Symptoms

We have several alerts that detect replication problems:

* Alert that replication is stopped
* Alert that replication lag is over 2min
* Alert that replication lag is over 200MB

As well there are a few alerts that are intended to detect problems that could *lead* to replication problems:

* Alert for disk utilization maxed out
* Alert for XLOG consumption is high

### Possible checks

* Monitoring

* Also check for bloat (see the section "Tables with a large amount of
  dead tuples" below). Replication lag can cause bloat on the primary
  due to "vacuum feedback" which we have enabled.

### Resolution

Look into whether there's a particularly heavy migration running which
may be generating very large WAL traffic that the replication can't
keep up with.

Not yet on the dashboards but you can look at
`rate(pg_xlog_position_bytes[1m]) ` compared with `pg_replication_lag`
to see if the replication lag is correlated with unusually high WAL
generation and what time it started.

Another cause of replication lag to investigate is a long-running
query on the replica which conflicts with a vacuum operation from the
primary. This should not be common because we don't generally run many
long-running queries on gitlab.com and we have vacuum feedback
enabled.

Just wait, replication self recovers :wine_glass:

## Replication Slots

### Symptoms

An unused replication slot in a primary will cause the primary to keep
around a large and growing amount of WAL (XLOG). This can eventually
cause low disk space free alerts and even an outage.

### Possible checks

* Look in `select * from pg_replication_slots where NOT active`, for both the
  primary and the secondaries.

### Resolution

Verify that the slot is indeed not needed any more. Note that after
dropping the slot Postgres will be free to delete the WAL data that
replica would have needed to resume replication. If it turns out to be
needed that replica will likely have to be recreated from scratch.

Drop the replication slot with `SELECT pg_drop_replication_slot('slot_name');`

It's possible for a secondary to have one or more inactive replication slots. In
this case the `xmin` value in `pg_replication_slots` _on the primary_ may start
lagging behind. This in turn can prevent vacuuming from removing dead tuples.
This can be solved by dropping the replication slots _on the secondaries_.

## Tables with a large amount of dead tuples

### Symptoms

* Alert that there is a table with too many dead tuples

Also a number of other alerts which link here because they detect
conditions which will lead to dead tuple bloat:

* Alert on "replication slot with a stale xmin"
* Alert on "long-lived transaction"

### Possible Checks

Check on Grafana dashboards, in particular the "Postgres Tuple Stats"
and the "Vacumming" and "Dead Tuples" tabs.

In the "Autovacuum Per Table" chart expect `project_mirror_data` and
`ci_runners` to be showing about 0.5 vacuums per minute and other
tables well below that. If any tables are much over 0.5 that's not
good. If any tables are near 1.0 (1 vacuum per minute is the max our
settings allow autovacuum to reach) then that's very bad.

In the "Dead Tuple Rates" and "Total Dead Tuples" expect to see a lot
of fluctations but no trend. If you see "Total Dead Tuples" rising
over time (or peaks that are rising each time) for a table then
autovacuum is failing to keep up.

If the alert is for dead tuples then it will list which table has a
high number of dead tuples however note that sometimes when one table
has this problem there are other tables not far behind that just
haven't alerted yet. Run
`sort_desc(pg_stat_table_n_dead_tup{environment="prd"})` in prometheus
to see what the top offenders are.

If the alert is for "replication slot with stale xmin" or "long-lived
transaction" then check the above charts to see if it's already
causing problems. Log into the relevant replica and run:

```sql
SELECT now()-xact_start,pid,query,client_addr,application_name
  FROM pg_stat_activity
 WHERE state != 'idle'
   AND query NOT LIKE 'autovacuum%'
 ORDER BY now()-xact_start DESC
 LIMIT 3;
```

There are any of three cases to check for:

1. There's a large number of dead tuples which vacuum is being
   ineffective at cleaning up due to a long-lived transaction
   (possibly on a replica due to "replication slot with a stale xmin").
1. There's a large rate of dead tuples being created due to a run-away
   migration or buggy controller which autovacuum cannot hope to keep
   up with.
1. There's a busy table that needs specially tuned autovacuum settings
   to vacuum it effectively.

If there's a deploy running or recent deploy with background
migrations running then check for a very high "Deletes" or "Updates"
rate on a table. Also check for for signs of other problems such as
replication lag, high web latency or errors, etc.

If the problem is due to a migration and the dead tuples are high but
not growing and it's not causing other problems then it can be a
difficult judgement call whether the migratin should be allowed to
proceed. Migrations are a generally a one-off case-by-case judgement.

If the "Total Dead Tuples" is increasing over time then canceling the
migration and reverting the deploy is probably necessary. Similarly if
the source of the dead tuple thrashing is determined to be from a
buggy web or api endpoint (or if it can't be determined at all.)

If the source is determined and it's necessary and expected that it
perform a high rate of updates or deletes on a table then it can be
accomodated by adjusting the autovacuum settings. Typically this is
necessary for small frequently updated state tables which are better
handled using Redis variables.

Adjust the vacuum settings for the given table to match the other
tables, like this:

```json
roles/gitlab-base-db-postgres.json
"push_event_payloads": {
  "autovacuum_analyze_scale_factor": 0,
  "autovacuum_vacuum_scale_factor": 0,
  "autovacuum_vacuum_threshold": 5000,
  "autovacuum_analyze_threshold": 10000
},
```

## Connections

This could indicate a problem with the pgbouncer setup as it's our
primary mechanism for concentrating connections. It should be
configured to use a limited number of connections.

Also check `pg_stat_activity` to look for old console sessions or
non-pgbouncer clients such as migrations or deploy scripts. Look in
particular for `idle` or `idle in transaction` sessions or sessions
running very long-lived queries.

e.g.:

```SQL
SELECT pid,
       age(backend_start) AS backend_age,
	   age(xact_start) AS xact_age,
	   age(query_start) AS query_age,
	   state,
	   query
  FROM pg_stat_activity
 WHERE pid <> pg_backend_pid()
```

Also, FYI "prepared transactions" and replication connections both
contribute to connection counts. There should be zero prepared
transactions on gitlab.com and only a small number of replication
connections (2 currently).

## PGBouncer Errors

If this is for the label `no more connections allowed
(max_client_conn)` then the number of incoming connections from all
clients is larger than `max_client_conn`. If this is the main
pgbouncer node then this means all connections from all processes and
threads on all hosts.

You can raise the `max_client_conn` temporarily by logging into the
pgbouncer console and issuing a command. First verify that the `ulimit
-n` is high enough using prlimit (which can also set it). And get the
password for pgbouncer console from 1password under `Production -
gitlab` and `Postgres pgbouncer user`:

```
# ps auxww |grep bin[/]pgbouncer
gitlab-+ 109886 34.4  0.6  28888 12836 ?        Rs   Mar19 13929:17 /opt/gitlab/embedded/bin/pgbouncer /var/opt/gitlab/pgbouncer/pgbouncer.ini

# prlimit -n -p 109886
RESOURCE DESCRIPTION               SOFT  HARD UNITS
NOFILE   max number of open files 50000 50000

# sudo gitlab-ctl pgb-console
Password for user pgbouncer: ...

psql (9.6.5, server 1.7.2/bouncer)
Type "help" for help.

pgbouncer=# show config;
            key            |                           value                            | changeable
---------------------------+------------------------------------------------------------+------------
 max_client_conn           | 2048                                                       | yes
...

pgbouncer=# show pools;
          database           |   user    | cl_active | cl_waiting | sv_active | sv_idle | sv_used | sv_tested | sv_login | maxwait |  pool_mode
-----------------------------+-----------+-----------+------------+-----------+---------+---------+-----------+----------+---------+-------------
 gitlabhq_production         | gitlab    |       925 |          0 |        50 |      50 |       0 |         0 |        0 |       0 | transaction
 gitlabhq_production         | pgbouncer |         0 |          0 |         0 |       0 |       1 |         0 |        0 |       0 | transaction
 gitlabhq_production_sidekiq | gitlab    |      1088 |          0 |        56 |      69 |       0 |         0 |        0 |       0 | transaction
 gitlabhq_production_sidekiq | pgbouncer |         0 |          0 |         0 |       1 |       0 |         0 |        0 |       0 | transaction
 pgbouncer                   | pgbouncer |         1 |          0 |         0 |       0 |       0 |         0 |        0 |       0 | statement
(5 rows)

pgbouncer=# set max_client_conn=4096;
```

Note in the above `show pools` command the `cl_active` column lists a
total of 2013 active client connections (not including our
console). Just 35 short of the `max_client_conn` of 2048.

If this is an alert for any other error you're on your own. But be
aware that it could be caused by something mundane such as an admin
typing commands at the console generating "invalid command" errors or
the database server restarting or clients dying.


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

* Alert that replication is lagging behind

### Possible checks

* Monitoring

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

* Look in `select * from pg_replication_slots where NOT active`

### Resolution

Verify that the slot is indeed not needed any more. Note that after
dropping the slot Postgres will be free to delete the WAL data that
replica would have needed to resume replication. If it turns out to be
needed that replica will likely have to be recreated from scratch.

Drop the replication slot with `SELECT pg_drop_replication_slot('slot_name');`

## Tables with a large amount of dead tuples

### Symptoms

* Alert that there is a table with too many dead tuples

### Possible Checks

The alert will list which table has a high number of dead tuples
however note that sometimes when one table has this problem there are
other tables not far behind that just haven't alerted yet. Run
`sort_desc(pg_stat_table_n_dead_tup{environment="prd"})` in prometheus
to see what the top offenders are.

Adjust the vacuum settings for the given table to match the other tables, like this:

```json roles/gitlab-base-db-postgres.json
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

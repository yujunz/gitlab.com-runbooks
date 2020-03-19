## Steps to check

1. Login to server.
1. Look for component="rule manager" errors in the log file. (`/var/log/prometheus/prometheus/current`)

Mistakes in recording and alerting rules can cause gaps in visibility. This can
be caused by changes to the environment, in addition to changes in the rules.

For example, label matching problems can cause alerts to not fire.

```
2018-11-23_17:19:28.66453 level=warn ts=2018-11-23T17:19:28.66428469Z caller=manager.go:408
  component="rule manager"
  group=postgresql.rules
  msg="Evaluating rule failed"
  rule="alert: PostgreSQL_ReplicationLagBytesTooLarge\nexpr: (pg_xlog_position_bytes and pg_replication_is_replica == 0) - on(environment)\n  group_right(instance) (pg_xlog_position_bytes and pg_replication_is_replica{type=\"postgres\"}\n  == 1) > 1e+09\nfor: 5m\nlabels:\n  channel: database\n  pager: pagerduty\n  severity: s1\nannotations:\n  description: Replication lag on server {{$labels.instance}} is currently {{ $value\n    | humanize1024}}B\n  runbook: docs/patroni/postgres.md#replication-is-lagging-or-has-stopped\n  title: Postgres Replication lag (in bytes) is high\n"
  err="many-to-many matching not allowed: matching labels must be unique on one side"
```

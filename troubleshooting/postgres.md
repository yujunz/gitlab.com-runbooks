# Postgresql troubleshooting

## First and foremost

*Don't Panic*

## Replication is lagging or has stopped

### Symptoms

* Alert that replication is lagging behind

### Possible checks

* Monitoring

### Resolution

Just wait, replication self recovers :wine_glass:

## Tables with a large amount of dead tuples

### Symptoms

* Alert that there is a table with too many dead tuples

### Posible Checks

* Run `sort_desc(pg_stat_table_n_dead_tup{environment="prd"})` in prometheus to see which table is the one with a lot of dead tuples

Adjust the vacuum settings for the given table to match the other tables, like this:

```json roles/gitlab-base-db-postgres.json
"push_event_payloads": {
  "autovacuum_analyze_scale_factor": 0,
  "autovacuum_vacuum_scale_factor": 0,
  "autovacuum_vacuum_threshold": 5000,
  "autovacuum_analyze_threshold": 10000
},
```

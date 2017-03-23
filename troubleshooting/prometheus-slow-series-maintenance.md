# Prometheus Series Maintenance Stalled

## Symptoms

Prometheus is maintaining (persisting, archiving, truncating, purging, ...) memory
time series so slowly that it will take a too long time to complete a full cycle.
This will lead to persistence falling behind.

## Possible checks

Did the number of time series increase recently?
Graph `prometheus_local_storage_memory_series` to see. Also check the
rate of maintained series: `rate(prometheus_local_storage_series_ops_total{type="maintenance_in_memory"}[5m]`

In general, any kind of load can contribute to slow series maintenance,
but most of the times, this is caused by trying to handle too many time series
in one Prometheus server.

## Resolution

Reduce the load on the Prometheus server, especially the number of handled
or changing time series.
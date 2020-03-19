# Prometheus Persistence Pressure Too High

## Symptoms

Prometheus is approaching critical persistence pressure, meaning that it cannot
keep up with persisting the number of ingested samples. Eventually, ingestion
will be throttled as a result of this.

## Possible checks

Did the number of time series increase recently?
Graph `prometheus_local_storage_memory_series` to see.

In general, any kind of load can contribute to a persistence pressure,
but most of the times, this is caused by trying to handle too many time series
or a too high scrape frequency in one Prometheus server.

## Resolution

Reduce the load on the Prometheus server, especially the number of handled
or changing time series.
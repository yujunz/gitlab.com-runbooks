# Prometheus Indexing Backlog

## Symptoms

Prometheus is taking a long time to index new time series, and thus newly
appearing series take a while to be queryable.

## Possible checks

Did the number of time series increase recently?
Graph `prometheus_local_storage_memory_series` to see.

How did the indexing queue develop? See `prometheus_local_storage_indexing_queue_length`.
Is it going down? Was it just one temporary spike of many new metrics?

In general, any kind of load can contribute to an indexing backlog,
but most of the times, this is caused by trying to handle too many time series
in one Prometheus server.

## Resolution

Reduce the load on the Prometheus server, especially the number of handled
or changing time series.
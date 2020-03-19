# Prometheus High Memory Utilization

## Symptoms

Prometheus RSS is using a large amount of the system memory.

Prometheus uses RSS automatically, as needed for data ingestion and running queries. It also needs a reasonable amount of pagecache to buffer TSDB data in memory for running queries.

## Possible checks

See the following articles:

* [Prometheus Storage docs](https://prometheus.io/docs/prometheus/latest/storage/)
* [Analysing Prometheus Memory Usage](https://www.robustperception.io/analysing-prometheus-memory-usage)

The following queries may also be helpful:

* `sum by (job) (scrape_samples_post_metric_relabeling)`
* `rate(prometheus_tsdb_head_samples_appended_total[5m])`

## Resolution

* Move some jobs to dedicated Prometheus servers.
* Increase the VM memory.
* Find expensive queries or rules and optimize them.

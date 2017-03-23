# Prometheus Scraping Slowly

## Symptoms

Prometheus is scraping targets slowly. New metrics will appear slower than
desired by configuration or not at all.

## Possible checks

See how `prometheus_target_interval_length_seconds{quantile="0.9"}` developed
over time. Did `count(up)` increase recently to indicate a higher number of
targets? Did `prometheus_local_storage_memory_series` increase recently to
indicate an overall larger number of time series that are scraped? Are the
targets themselves responsive on their `/metrics` endpoint?

## Resolution

Depending on the above, either lower the load on Prometheus by reducing the
number of targets or time series, or ensure that your targets are quickly
scrapable.
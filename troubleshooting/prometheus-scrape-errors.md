## Steps to check

1. Login to server.
1. Look for large scrape errors in the log file. (`/var/log/prometheus/prometheus/current`)
1. Look at the scrape metrics to find large instances. `topk(10, scrape_samples_scraped)`

Prometheus has a built-in limiter for the number of samples returned by a
single target. This is controlled at the job level with the `sample_limit`
option. The default is unlimited samples.

Look at the metrics output of the target
(ex. `curl -s 'http://node:9100/metrics'`) to see if there are any obvious
problems with label cardinality.

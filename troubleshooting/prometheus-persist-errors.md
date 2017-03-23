# Prometheus Persist Errors

## Symptoms

Prometheus is encountering errors while persisting sample chunks.

## Possible checks

See how `rate(prometheus_local_storage_persist_errors_total[10m])` developed
over time. Log in to the machine and check the Prometheus logs to see the
exact error that is occurring. Most likely, the disk is full or there are
IO errors.

## Resolution

If the disk is full, either change the retention time, use a larger disk,
or put less time series on the Prometheus.

If there are other errors in the log, address those.
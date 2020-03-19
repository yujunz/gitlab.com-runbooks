## Steps to check

1. Login to server.
1. Look for wal errors in the log file. (`/var/log/prometheus/prometheus/current`)

Prometheus truncates the Write Ahead Log as it creates new compacted TSDB
segments. Check the log to see why WAL truncations are failing.

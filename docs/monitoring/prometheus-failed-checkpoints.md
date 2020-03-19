## Steps to check

1. Login to server.
1. Look for checkpoint errors in the log file. (`/var/log/prometheus/prometheus/current`)

Prometheus can create checkpoints in its WAL. Check the log to find out what
failed. Possible issues could be permissions or out of disk space errors.

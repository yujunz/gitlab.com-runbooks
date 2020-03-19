## Steps to check

1. Login to server.
1. Look for compaction errors in the log file. (`/var/log/prometheus/prometheus/current`)

Possible sources of compactions are corruptions from crashes (OOM, bug, etc). If unable to find the source of the comapction problem, or if the problem does not correct itself, contact the monitoring team. (monitoring-team@gitla.com, `#g_monitor`)

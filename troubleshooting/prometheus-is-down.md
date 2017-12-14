## Steps to check

1. Login to server - `prometheus.gitlab.com` or `prometheus-2.gitlab.com`. Check service with `sv status prometheus`. If it is `run` for more than `0s`. Then it is ok.
1. If it is `down` state, then check logs in `/var/log/prometheus/prometheus/current`. Actions can be taken after logs investigating. Usually it is configuration error or IO/space problems.

## How to work with Prometheus

1. Check configuration - `/opt/prometheus/prometheus/promtool check-config /opt/prometheus/prometheus/prometheus.yml`.
It should check prometheus configuration file and alerts being used. Please always run this check before restarting prometheus service.
1. Reload configuration - `sudo sv reload prometheus`.
1. Restart service - `sudo sv restart prometheus` after checking configuration.

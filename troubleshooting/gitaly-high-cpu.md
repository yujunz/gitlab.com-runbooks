# Gitaly CPU too high on a file server

## First and foremost

*Don't Panic*

## Symptoms

* Message in prometheus-alerts _Gitaly: High CPU usage on host_

## 1. Check status and restart

- Open the [**Gitaly NFS Metrics per Host** dashboard](https://performance.gitlab.net/dashboard/db/gitaly-nfs-metrics-per-host?refresh=30s&orgId=1&var-fqdn=nfs-file-08.stor.gitlab.com&from=now-1h&to=now) making sure to select the correct host,
  and check the metrics
- Log into the NFS server through a shell
- Use `uptime` to check the current load values on the box
- Use top to check whether or not Gitaly is using very high levels of CPU
- Attempt to restart gitaly service: `sudo gitlab-ctl restart gitaly`

_In future, this may include details on profiling the process before restarting it_

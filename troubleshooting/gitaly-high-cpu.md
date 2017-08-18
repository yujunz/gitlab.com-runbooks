# Gitaly CPU too high on a file server

## First and foremost

*Don't Panic*

## Symptoms

* Load spike on the NFS servers, high I/O load.
* Message in prometheus-alerts _Gitaly: High CPU usage on host_

## Possible checks

- Open the [**Gitaly NFS Metrics per Host** dashboard](https://performance.gitlab.net/dashboard/db/gitaly-nfs-metrics-per-host?refresh=30s&orgId=1&var-fqdn=nfs-file-08.stor.gitlab.com&from=now-1h&to=now) making sure to select the correct host,
  and check the metrics
- Log into the NFS server through a shell
- Use `uptime` and `iotop` to check the current load values on the box
- Use top to check whether or not Gitaly is using very high levels of CPU
- As a last resort, restart the gitaly service: `sudo gitlab-ctl restart gitaly`. **This has service impact.**

### Long running or orphan `git-receive-pack` processes

It is possible for there to be orphan git processes that can cause heavy I/O and increase the load on the server.
This can happen when a large amount of data is being pushed to a git repository.
First follow the "Possible checks" above, especially the load average and run `iotop` on the server.
Look for processes matching `git-receive-pack path/to/some/repo.git`.

Normally, `git-receive-pack` be a child of `gitlab-shell` with a short run-time, for example:
```
git      57746 57732  0 14:56 ?        00:00:00 sh -c /opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell key-1313921
git      57747 57746  9 14:56 ?        00:00:00 git-receive-pack /path/to/repo.git
```

There may be long running git-receive-pack processes that are orphan, you can do a basic search for orphan processes belonging to git using the following command:

```
pgrep -a -u git -P 1
```
If you see long running `git-receive-pack` orphan processes they can be killed.

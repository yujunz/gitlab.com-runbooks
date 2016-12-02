## Reason

GitLab registry is not responding or returns not 200 OK statuses.

## Possible checks

1. Open https://registry.gitlab.com and if you are seeing empty page, not 4xx or 5xx error page, then everything is ok.
1. Also you can check by running `knife ssh role:gitlab-cluster-worker 'sudo gitlab-ctl status registry'`. If you are seeing messages like `worker15.cluster.gitlab.com run: registry: (pid 1091) 2107486s; run: log: (pid 1085) 2107486s`, then also everything is fine. If registry is not working you will be seeing services in `down` state.

## What to do?

1. Try restart service with the command `sudo gitlab-ctl restart registry` if it is down.

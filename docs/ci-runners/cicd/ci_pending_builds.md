## Large CI pending builds
Alert Name: CICDTooManyPendingJobsPerNamespace or CICDTooManyRunningJobsPerNamespaceOnSharedRunnersGitLabOrg

The most comment problem is that we get a report that we have a large number of CI pending builds.

1. Check `CI dashboard` and verify that we have a large number of CI builds,
2. Verify graphs and potential outcomes out of the graphs as described in (CI graphs)[ci_graphs.md],
3. Verify if we have [the high DO Token Rate Limit usage](ci_runner_manager_do_limits.md),
4. Verify the number of errors [the high number of errors](ci_runner_manager_errors.md),
5. Verify that machines are created on `shared-runners-manager-X.gitlab.com`,
6. Verify that docker machine valid operation,

## 1. Check `CI dashboard` and verify that we have a large number of CI builds

Look at the graph with number of CI builds:
![](../img/ci/jobs_graph.png)

## 2. Verify graphs and potential outcomes out of the graphs as described in (CI graphs)[ci_graphs.md],

To understand what can be wrong, you need to find a cause.

1. Check runner auto-scaling: [CI auto-scaling graphs](ci_graphs.md#runners-manager-auto-scaling),
   and look for the `Idle` number,
2. Verify jobs queues: [CI auto-scaling graphs](ci_graphs.md#jobs-queue).
   If you see a single namespace with a lot of builds, verify what projects are in that namespace and whether this is the abuser.
3. Verify long polling behavior (we are not yet aware of potential problems as of now),
4. Verify workhorse queueing: [Workhorse queueing graphs](ci_graphs.md#workhorse-queueing).
   If you see a large number of requests ending up in the queue it may indicate that CI API is degraded.
   Verify the performance of `builds/register` endpoint: https://dashboards.gitlab.net/dashboard/db/grape-endpoints?var-action=Grape%23POST%20%2Fbuilds%2Fregister&var-database=Production,
5. Verify runners uptime. If you see that runners uptime is varying it does indicate that most likely Runners Manager does die, because of the crash. It will be shown in runners manager logs: `grep panic /var/log/messages`.

## 3. Verify if we have [the high DO Token Rate Limit usage](ci_runner_manager_do_limits.md)

You will see alerts on `#alerts` channel. It will indicate that since we are hitting API limits we will no longer be able to provision new machines.

## 4. Verify the number of errors [the high number of errors](ci_runner_manager_errors.md)

Generally, it is not a big problem, but it generates a lot of noise in logs. It is safe to run that runbook.

You should also be aware that you should then cross-check state between digital ocean and runners manager as described in
that issue: https://gitlab.com/gitlab-com/infrastructure/issues/921 (this should be moved to script and runbook).

## 5. Verify that machines are created on `shared-runners-manager-X.gitlab.com`

Login to runners manager and execute:

```bash
$ journalctl -xef | grep "Machine created"
```

You should see a constant stream of machines being created:

```
Mar 20 13:16:36 shared-runners-manager-2 gitlab-ci-multi-runner[19931]: time="2017-03-20T13:16:36Z" level=info msg="Machine created" fields.time=43.913563388s name=runner-4e4528ca-machine-1490015752-629c75cb-digital-ocean-4gb now=2017-03-20 13:16:36.246859005 +0000 UTC retries=0 time=43.913563388s
```

If you don't see it, try to debug logs from docker machine:

```bash
journalctl -xef | grep operation=create
```

```
Mar 20 13:17:56 shared-runners-manager-2 gitlab-runner[19931]: time="2017-03-20T13:17:56Z" level=info msg="Running pre-create checks..." driver=digitalocean name=runner-4e4528ca-machine-1490015876-441093ee-digital-ocean-4gb operation=create
Mar 20 13:17:57 shared-runners-manager-2 gitlab-runner[19931]: time="2017-03-20T13:17:57Z" level=info msg="Creating machine..." driver=digitalocean name=runner-4e4528ca-machine-1490015876-441093ee-digital-ocean-4gb operation=create
Mar 20 13:17:57 shared-runners-manager-2 gitlab-runner[19931]: time="2017-03-20T13:17:57Z" level=info msg="(runner-4e4528ca-machine-1490015876-441093ee-digital-ocean-4gb) Creating SSH key..." driver=digitalocean name=runner-4e4528ca-machine-1490015876-441093ee-digital-ocean-4gb operation=create
Mar 20 13:17:58 shared-runners-manager-2 gitlab-runner[19931]: time="2017-03-20T13:17:58Z" level=info msg="(runner-4e4528ca-machine-1490015876-441093ee-digital-ocean-4gb) Creating Digital Ocean droplet..." driver=digitalocean name=runner-4e4528ca-machine-1490015876-441093ee-digital-ocean-4gb operation=create
Mar 20 13:18:03 shared-runners-manager-2 gitlab-runner[19931]: time="2017-03-20T13:18:03Z" level=info msg="(runner-4e4528ca-machine-1490015876-441093ee-digital-ocean-4gb) Waiting for IP address to be assigned to the Droplet..." driver=digitalocean name=runner-4e4528ca-machine-1490015876-441093ee-digital-ocean-4gb operation=create
Mar 20 13:18:04 shared-runners-manager-2 gitlab-runner[19931]: time="2017-03-20T13:18:04Z" level=info msg="(runner-4e4528ca-machine-1490015876-441093ee-digital-ocean-4gb) Created droplet ID 42980631, IP address 159.203.179.170" driver=digitalocean name=runner-4e4528ca-machine-1490015876-441093ee-digital-ocean-4gb operation=create
Mar 20 13:18:34 shared-runners-manager-2 gitlab-runner[19931]: time="2017-03-20T13:18:34Z" level=info msg="Waiting for machine to be running, this may take a few minutes..." driver=digitalocean name=runner-4e4528ca-machine-1490015876-441093ee-digital-ocean-4gb operation=create
```

If it fails to create you will see a message here.

## 6. Verify that docker machine valid operation

You should try to create machine manually:

```bash
$ docker-machine create -d google test-machine --google-project=gitlab-ci-155816 --google-disk-size=25 --google-machine-type=n1-standard-1 --google-username=core --google-operation-backoff-initial-interval=2 --google-subnetwork=shared-runners --google-zone=us-east1-d --engine-opt=mtu=1460 --engine-opt=ipv6 --engine-opt=fixed-cidr-v6=fc00::/7 --google-scopes=https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write --google-machine-image=gitlab-ci-155816/global/images/runners-coreos-stable-v20190822-0
```

This method should succeed. If it does not. You have to verify it.

Once it is created you can log in to this created machine:

```bash
$ docker-machine ssh test-machine
```

And try to run some docker containers, to verify that networking, DNS does work properly.

```bash
$ docker run -it docker:git /bin/sh
# git clone https://gitlab.com/gitlab-org/gitlab-ce
```

Afterward tear down the machine:
```bash
$ docker-machine rm test-machine
```

If it fails at any of the commands it can mean any of that:
1. there's a problem with docker-machine creating machine,
2. there's a problem with docker-engine on machine,
3. there's a problem with connectivity from docker-machine.

You may need to:
1. verify if it's a problem of `docker version`,
1. verify if it's a problem of `coreos-stable`,
2. verify if it's a problem of networking out of the container: DNS?

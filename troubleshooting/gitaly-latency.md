# Gitaly latency is too high

## Note

This runbook will be deprecated in favor of the [gitaly pprof runbook](https://gitlab.com/gitlab-org/gitaly/issues/776) once `pprof` is available in production.

## Symptoms

* Alert on PagerDuty _Gitaly latency on <hostname> has been over 1m during the last 5m_
* General SLO alert on Gitaly service latency.
* This may also be affecting web / git-frontend latency.

## 1. Check the triage dashboard to assess the impact

- Visit the **[Triage Dashboard](https://dashboards.gitlab.net/dashboard/db/triage-overview)**.
- Check the **Gitaly p95 latency** graph and identify the offending server or servers.

## 2. Drill down

- Look at the [RPC time by project
  graph](https://log.gitlab.net/app/kibana#/visualize/edit/AW3YxmNOzxfRAgEaOtW6).
  Does it reveal any few projects that are responsible for RPC time?
- If a project is responsible for a lot of RPC time, filter the graph by that
  project and change the X-axis grouping to method.

## 3. Common causes and remedies

### PostUploadPack on popular project

This usually means that a lot of clients are fetching the project. Performance
issues here are usually transient.

### GetBlob on project

Open the [Rails request duration by controller per project
graph](https://log.gitlab.net/app/kibana#/visualize/edit/AW3Z_bgiQ7jyVXjiZ19E).
Change the project filter appropriately. If the RawController is using most
time, it's possible that the repo is being used as a static content backend.
This is often fine, but it's worth looking inside the repo using your admin
account to see what sort of files are being served up. Exercise judgement in
whether or not to block the account, notifying support and/or SecOps if you do.

## 4. Debug Gitaly

- If you cannot engage anyone from the Gitaly team, you might want to restart the `gitaly` process.
  - Log into the affected server.
  - Issue a `sudo kill -6 <GITALY_SERVER_PID>` to dump goroutines info to logs.
  - If the command above didn't restart the process, then issue `sudo gitlab-ctl restart gitaly`.
  - Extract the dump info from the logs for further inspections or inform one of the Gitaly engineers.

# Gitaly is down

## Symptoms

* Message in prometheus-alerts _Gitaly: two versions of Gitaly have been running in production for more than 30 minutes_

## 1. Figure out which version of Gitaly are running, and on what hosts

Several versions of Gitaly are running in production concurrently.

Visit the [Gitaly Version Tracker](https://dashboards.gitlab.net/dashboard/db/gitaly-version-tracker?orgId=1&var-environment=prd)
dashboard to find out which versions are running on each host.

If a deployment is currently being carried out there may be two versions running alongside
one another for a period of up to 30 minutes.

Longer periods indicate a problem with the deployment, including

* Have hosts been skipped from the deployment?
* Is the deployment stuck?

## 2. Figure out which version of Gitaly is the expected version

The correct version of Gitaly can be found in the [`GITALY_SERVER_VERSION`](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/GITALY_SERVER_VERSION) file in the Gitlab CE repository.

(Remember to switch branches to choose the correct version of GitLab CE)

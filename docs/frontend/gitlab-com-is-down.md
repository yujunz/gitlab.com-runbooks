## Steps to check

1. Check network, try to open [GitLab.com](https://gitlab.com). If it is ok from your side, then it can be only network failure.
1. Check the [triage dashboard](https://dashboards.gitlab.net/d/RZmbBr7mk/gitlab-triage?refresh=30s&orgId=1).
1. Check the [fleet overview](on http://dashboards.gitlab.net/dashboard/db/fleet-overview).
1. Check the [database overview](https://dashboards.gitlab.net/d/000000144/postgresql-overview?orgId=1).
1. Check the [pgbouncer overview](https://dashboards.gitlab.net/d/PwlB97Jmk/pgbouncer-overview?orgId=1).

## Things to Look for
* Look for resource exhaustion of the pgbouncer connections

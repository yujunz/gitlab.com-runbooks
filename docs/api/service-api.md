<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Api Service

* **Responsible Teams**:
  * [create](https://about.gitlab.com/handbook/engineering/dev-backend/create/). **Slack Channel**: [#g_create](https://gitlab.slack.com/archives/g_create)
  * [distribution](https://about.gitlab.com/handbook/engineering/dev-backend/distribution/). **Slack Channel**: [#distribution](https://gitlab.slack.com/archives/distribution)
  * [geo](https://about.gitlab.com/handbook/engineering/dev-backend/geo/). **Slack Channel**: [#g_geo](https://gitlab.slack.com/archives/g_geo)
  * [gitaly](https://about.gitlab.com/handbook/engineering/dev-backend/gitaly/). **Slack Channel**: [#gitaly](https://gitlab.slack.com/archives/gitaly)
  * [gitter](https://about.gitlab.com/handbook/engineering/dev-backend/gitter/). **Slack Channel**: [#g_gitaly](https://gitlab.slack.com/archives/g_gitaly)
  * [manage](https://about.gitlab.com/handbook/engineering/dev-backend/manage/). **Slack Channel**: [#g_manage](https://gitlab.slack.com/archives/g_manage)
  * [plan](https://about.gitlab.com/handbook/engineering/dev-backend/manage/). **Slack Channel**: [#g_plan](https://gitlab.slack.com/archives/g_plan)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=api&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22api%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:API"

## Logging

* [Rails](https://log.gprd.gitlab.net/goto/0238ddb1480bb4bd19c09f0467b6e684)
* [Workhorse](https://log.gprd.gitlab.net/goto/eb99f28c17cfcdfd30969a1c85e209dc)
* [Unicorn](https://log.gprd.gitlab.net/goto/c8f89b2415788b46978fcd2910b4afec)
* [nginx](https://log.gprd.gitlab.net/goto/0d1c84486d6fb28a785f1c21473e5611)
* [Unstructured Rails](https://console.cloud.google.com/logs/viewer?project=gitlab-production&interval=PT1H&resource=gce_instance&advancedFilter=jsonPayload.hostname%3A%22api%22%0Alabels.tag%3D%22unstructured.production%22&customFacets=labels.%22compute.googleapis.com%2Fresource_name%22)
* [system](https://log.gprd.gitlab.net/goto/2b9679dab019791136cb8ae1535fb781)

## Troubleshooting Pointers

* [../ci-runners/create-runners-manager-node.md](../ci-runners/create-runners-manager-node.md)
* [../ci-runners/pipeline-deletion.md](../ci-runners/pipeline-deletion.md)
* [../ci-runners/tracing-app-db-queries.md](../ci-runners/tracing-app-db-queries.md)
* [../frontend/haproxy-1.md](../frontend/haproxy-1.md)
* [../frontend/haproxy.md](../frontend/haproxy.md)
* [../frontend/ssh-maxstartups-breach.md](../frontend/ssh-maxstartups-breach.md)
* [../git/deploy-gitlab-rb-change.md](../git/deploy-gitlab-rb-change.md)
* [../git/purge-git-data.md](../git/purge-git-data.md)
* [../gitaly/gitaly-token-rotation.md](../gitaly/gitaly-token-rotation.md)
* [../gitaly/storage-rebalancing.md](../gitaly/storage-rebalancing.md)
* [../gitaly/storage-servers.md](../gitaly/storage-servers.md)
* [../monitoring/alertmanager-notification-failures.md](../monitoring/alertmanager-notification-failures.md)
* [../monitoring/alerts_manual.md](../monitoring/alerts_manual.md)
* [../patroni/patroni-management.md](../patroni/patroni-management.md)
* [../patroni/postgres.md](../patroni/postgres.md)
* [../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md](../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md)
* [../pgbouncer/pgbouncer.md](../pgbouncer/pgbouncer.md)
* [../runner/ci-runner-timeouts.md](../runner/ci-runner-timeouts.md)
* [../sidekiq/large-sidekiq-queue.md](../sidekiq/large-sidekiq-queue.md)
* [../uncategorized/blocked-user-logins.md](../uncategorized/blocked-user-logins.md)
* [../uncategorized/chef-documentation.md](../uncategorized/chef-documentation.md)
* [../uncategorized/gemnasium_is_down.md](../uncategorized/gemnasium_is_down.md)
* [../uncategorized/k8s-cluster-upgrade.md](../uncategorized/k8s-cluster-upgrade.md)
* [../uncategorized/k8s-gitlab.md](../uncategorized/k8s-gitlab.md)
* [../uncategorized/k8s-operations.md](../uncategorized/k8s-operations.md)
* [../uncategorized/manage-workers.md](../uncategorized/manage-workers.md)
* [../uncategorized/pingdom.md](../uncategorized/pingdom.md)
* [../uncategorized/upgrade-docker-machine.md](../uncategorized/upgrade-docker-machine.md)
* [../web/static-repository-objects-caching.md](../web/static-repository-objects-caching.md)
<!-- END_MARKER -->
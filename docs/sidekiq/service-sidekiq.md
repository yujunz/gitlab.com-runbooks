<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Sidekiq Service

* **Responsible Teams**:
  * [create](https://about.gitlab.com/handbook/engineering/dev-backend/create/). **Slack Channel**: [#g_create](https://gitlab.slack.com/archives/g_create)
  * [distribution](https://about.gitlab.com/handbook/engineering/dev-backend/distribution/). **Slack Channel**: [#distribution](https://gitlab.slack.com/archives/distribution)
  * [geo](https://about.gitlab.com/handbook/engineering/dev-backend/geo/). **Slack Channel**: [#g_geo](https://gitlab.slack.com/archives/g_geo)
  * [gitaly](https://about.gitlab.com/handbook/engineering/dev-backend/gitaly/). **Slack Channel**: [#gitaly](https://gitlab.slack.com/archives/gitaly)
  * [gitter](https://about.gitlab.com/handbook/engineering/dev-backend/gitter/). **Slack Channel**: [#g_gitaly](https://gitlab.slack.com/archives/g_gitaly)
  * [manage](https://about.gitlab.com/handbook/engineering/dev-backend/manage/). **Slack Channel**: [#g_manage](https://gitlab.slack.com/archives/g_manage)
  * [plan](https://about.gitlab.com/handbook/engineering/dev-backend/manage/). **Slack Channel**: [#g_plan](https://gitlab.slack.com/archives/g_plan)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=sidekiq&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22sidekiq%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Sidekiq"

## Logging

* [Sidekiq](https://log.gprd.gitlab.net/goto/d7e4791e63d2a2b192514ac821c9f14f)
* [Rails](https://log.gprd.gitlab.net/goto/86fbcd537588abef69339a352ef81d72)
* [Unicorn](https://log.gprd.gitlab.net/goto/c87a39cf228c45ed8691c855aa583170)
* [Unstructured](https://console.cloud.google.com/logs/viewer?project=gitlab-production&interval=PT1H&resource=gce_instance&advancedFilter=jsonPayload.hostname%3A%22sidekiq%22%0Alabels.tag%3D%22unstructured.production%22&customFacets=labels.%22compute.googleapis.com%2Fresource_name%22)
* [system](https://log.gprd.gitlab.net/goto/72d0f3fdfd8db18db9800cc04d8b6f55)

## Troubleshooting Pointers

* [../bastions/rm-bastion-access.md](../bastions/rm-bastion-access.md)
* [../ci-runners/load-balancing.md](../ci-runners/load-balancing.md)
* [../ci-runners/tracing-app-db-queries.md](../ci-runners/tracing-app-db-queries.md)
* [../elastic/elasticsearch-integration-in-gitlab.md](../elastic/elasticsearch-integration-in-gitlab.md)
* [../git/deploy-gitlab-rb-change.md](../git/deploy-gitlab-rb-change.md)
* [../gitaly/gitaly-token-rotation.md](../gitaly/gitaly-token-rotation.md)
* [../gitaly/storage-rebalancing.md](../gitaly/storage-rebalancing.md)
* [../logging/README.md](../logging/README.md)
* [../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md](../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md)
* [../pgbouncer/pgbouncer-1.md](../pgbouncer/pgbouncer-1.md)
* [../pgbouncer/pgbouncer.md](../pgbouncer/pgbouncer.md)
* [../redis/redis.md](../redis/redis.md)
* [large-pull-mirror-queue.md](large-pull-mirror-queue.md)
* [large-sidekiq-queue.md](large-sidekiq-queue.md)
* [sidekiq-inspection.md](sidekiq-inspection.md)
* [sidekiq_error_rate_high.md](sidekiq_error_rate_high.md)
* [sidekiq_stats_no_longer_showing.md](sidekiq_stats_no_longer_showing.md)
* [../uncategorized/debug-failed-chef-provisioning.md](../uncategorized/debug-failed-chef-provisioning.md)
* [../uncategorized/k8s-gitlab-operations.md](../uncategorized/k8s-gitlab-operations.md)
* [../uncategorized/manage-workers.md](../uncategorized/manage-workers.md)
* [../uncategorized/tweeting-guidelines.md](../uncategorized/tweeting-guidelines.md)
<!-- END_MARKER -->

<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Runner Service

* **Responsible Teams**:
  * [verify](https://about.gitlab.com/handbook/engineering/ops-backend/verify/). **Slack Channel**: [#g_verify](https://gitlab.slack.com/archives/g_verify)
  * [infrastructure-caches-ci-queues](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=runner&orgId=1
* **Alerts**: https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22runner%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Runner"

## Logging

* [system](https://log.gprd.gitlab.net/goto/9b8322ad2ddacec15c7c1691d6c67733)

## Troubleshooting Pointers

* [../ci-runners/README.md](../ci-runners/README.md)
* [../ci-runners/ci-investigate-abuse.md](../ci-runners/ci-investigate-abuse.md)
* [../ci-runners/create-runners-manager-node.md](../ci-runners/create-runners-manager-node.md)
* [../ci-runners/remove-broken-runners.md](../ci-runners/remove-broken-runners.md)
* [../ci-runners/runners_cache_disk_space.md](../ci-runners/runners_cache_disk_space.md)
* [../ci-runners/runners_manager_is_down.md](../ci-runners/runners_manager_is_down.md)
* [../ci-runners/runners_registry_is_down.md](../ci-runners/runners_registry_is_down.md)
* [../ci-runners/shared-runners-cost-factors.md](../ci-runners/shared-runners-cost-factors.md)
* [../license/license-gitlab-com.md](../license/license-gitlab-com.md)
* [../logging/README.md](../logging/README.md)
* [../pgbouncer/pgbouncer-saturation.md](../pgbouncer/pgbouncer-saturation.md)
* [ci-runner-timeouts.md](ci-runner-timeouts.md)
* [update-gitlab-runner-on-managers.md](update-gitlab-runner-on-managers.md)
* [../sidekiq/large-sidekiq-queue.md](../sidekiq/large-sidekiq-queue.md)
* [../uncategorized/about-gitlab-com.md](../uncategorized/about-gitlab-com.md)
* [../version/version-gitlab-com.md](../version/version-gitlab-com.md)
<!-- END_MARKER -->

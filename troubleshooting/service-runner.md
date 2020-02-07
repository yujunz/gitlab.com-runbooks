<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Runner Service

* **Responsible Teams**:
  * [verify](https://about.gitlab.com/handbook/engineering/ops-backend/verify/). **Slack Channel**: [#g_verify](https://gitlab.slack.com/archives/g_verify)
  * [infrastructure-caches-ci-queues](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=runner&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22runner%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Runner"

## Logging

* [system](https://log.gprd.gitlab.net/goto/9b8322ad2ddacec15c7c1691d6c67733)

## Troubleshooting Pointers

* [large-sidekiq-queue.md](large-sidekiq-queue.md)
* [pgbouncer.md](pgbouncer.md)
* [runners_cache_disk_space.md](runners_cache_disk_space.md)
* [runners_manager_is_down.md](runners_manager_is_down.md)
* [runners_registry_is_down.md](runners_registry_is_down.md)
* [version-gitlab-com.md](version-gitlab-com.md)
<!-- END_MARKER -->

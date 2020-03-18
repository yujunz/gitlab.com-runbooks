<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Console Service

* **Responsible Teams**:
  * [infrastructure-coreinfra](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
  * [infrastructure-webapp](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
  * [infrastructure-caches-ci-queues](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=console&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22console%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Console"

## Logging

* [history]()
* []()

## Troubleshooting Pointers

* [debug-failed-chef-provisioning.md](debug-failed-chef-provisioning.md)
* [filesystem_alerts.md](filesystem_alerts.md)
* [gemnasium_is_down.md](gemnasium_is_down.md)
* [gitaly-down.md](gitaly-down.md)
* [gitlab-com-wale-backups.md](gitlab-com-wale-backups.md)
* [gitlab-registry.md](gitlab-registry.md)
* [haproxy.md](haproxy.md)
* [kubernetes.md](kubernetes.md)
* [large-sidekiq-queue.md](large-sidekiq-queue.md)
* [missing_repos.md](missing_repos.md)
* [pages-letsencrypt.md](pages-letsencrypt.md)
* [pgbouncer.md](pgbouncer.md)
* [postgres.md](postgres.md)
* [redis.md](redis.md)
* [sidekiq_error_rate_high.md](sidekiq_error_rate_high.md)
* [sidekiq_stats_no_longer_showing.md](sidekiq_stats_no_longer_showing.md)
* [version-gitlab-com.md](version-gitlab-com.md)
* [workers-high-load.md](workers-high-load.md)
<!-- END_MARKER -->

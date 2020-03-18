<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Redis Service

* **Responsible Teams**:
  * [infrastructure-caches-ci-queues](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
  * [infrastructure-webapp](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=redis&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22redis%22%2C%20tier%3D%22db%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Redis"

## Logging

* [Redis](https://log.gprd.gitlab.net/goto/27a6bf4e347ef9da754f06eb0a54aedc)
* [system](https://log.gprd.gitlab.net/goto/e107ce00a9adede2e130d0c8ec1a2ac7)

## Troubleshooting Pointers

* [large-pull-mirror-queue.md](large-pull-mirror-queue.md)
* [redis.md](redis.md)
* [sentry-is-down.md](sentry-is-down.md)
* [sidekiq_stats_no_longer_showing.md](sidekiq_stats_no_longer_showing.md)
<!-- END_MARKER -->

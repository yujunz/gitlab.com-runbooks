<!-- MARKER: do not edit this section directly. Edit services/service-mappings.yml then run scripts/generate-docs -->
#  Sidekiq Service

* **Responsible Team**: [backend](https://about.gitlab.com/handbook/engineering/dev-backend/)
* **Slack Channel**: [#backend](https://gitlab.slack.com/archives/production/backend)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/WOtyonOiz/general-triage-service?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=sidekiq&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22sidekiq%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com~"Service:Sidekiq"
* **Sentry**: https://sentry.gitlap.com/gitlab/gitlabcom
* **Grafana Folder**: https://dashboards.gitlab.net/dashboards/f/c7nMugpmz
* **ELK**: [`pubsub-sidekiq-inf-gprd-*`](https://log.gitlab.net/goto/d7e4791e63d2a2b192514ac821c9f14f)

## Troubleshooting Pointers

* [ci_introduction.md](ci_introduction.md)
* [large-sidekiq-queue.md](large-sidekiq-queue.md)
* [sidekiq_stats_no_longer_showing.md](sidekiq_stats_no_longer_showing.md)

## Operating Rate

![](https://dashboards.gitlab.com/render/d-solo/WOtyonOiz/general-triage-service?from=now-24h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=sidekiq&orgId=1&panelId=12&width=1200&height=600&tz=UTC&theme=light)

<!-- END_MARKER -->

<!-- MARKER: do not edit this section directly. Edit services/service-mappings.yml then run scripts/generate-docs -->
#  Redis Service

* **Responsible Team**: [infrastructure](https://about.gitlab.com/handbook/engineering/infrastructure/)
* **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/WOtyonOiz/general-triage-service?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=redis&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22redis%22%2C%20tier%3D%22db%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Redis"
* **Grafana Folder**: https://dashboards.gitlab.net/dashboards/f/D5R0peIik
* **ELK**: [`pubsub-redis-inf-gprd-*`](https://log.gitlab.net/goto/27a6bf4e347ef9da754f06eb0a54aedc)

## Troubleshooting Pointers

* [ci_graphs.md](ci_graphs.md)
* [ci_introduction.md](ci_introduction.md)
* [large-pull-mirror-queue.md](large-pull-mirror-queue.md)
* [postgres.md](postgres.md)
* [redis_replication.md](redis_replication.md)
* [sentry-is-down.md](sentry-is-down.md)
* [sidekiq_stats_no_longer_showing.md](sidekiq_stats_no_longer_showing.md)
<!-- END_MARKER -->

<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Pubsub Service

* **Responsible Teams**:
  * [infrastructure-observability](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#observability](https://gitlab.slack.com/archives/observability)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=pubsub&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22pubsub%22%2C%20tier%3D%22inf%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:PubSub"

## Logging

* [stackdriver](https://console.cloud.google.com/logs)
* [multiple indexes in Kibana](https://log.gprd.gitlab.net/goto/2fc394521558a0bfed59f791295ffe51)

## Troubleshooting Pointers

* [camoproxy.md](camoproxy.md)
* [gitaly-pubsub.md](gitaly-pubsub.md)
* [gitlab-com-wale-backups.md](gitlab-com-wale-backups.md)
* [gitlab-registry.md](gitlab-registry.md)
* [praefect-error-rate.md](praefect-error-rate.md)
* [pubsub-queing.md](pubsub-queing.md)
<!-- END_MARKER -->

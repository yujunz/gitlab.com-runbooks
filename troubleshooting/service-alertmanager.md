<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Alertmanager Service

* **Responsible Teams**:
  * [infrastructure-observability](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#observability](https://gitlab.slack.com/archives/observability)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=alertmanager&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22alertmanager%22%2C%20tier%3D%22inf%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:AlertManager"

## Logging

* []()

## Troubleshooting Pointers

* [alertmanager-notification-failures.md](alertmanager-notification-failures.md)
* [prometheus-notifications-backlog.md](prometheus-notifications-backlog.md)
* [prometheus-snitch.md](prometheus-snitch.md)
<!-- END_MARKER -->

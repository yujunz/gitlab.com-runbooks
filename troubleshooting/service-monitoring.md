<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Monitoring Service

* **Responsible Teams**:
  * [infrastructure-observability](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#observability](https://gitlab.slack.com/archives/observability)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=monitoring&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22monitoring%22%2C%20tier%3D%22inf%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Prometheus"

## Logging

* [system](https://log.gprd.gitlab.net/goto/3a0b51d10d33c9558765e97640acb325)

## Troubleshooting Pointers

* [postgres.md](postgres.md)
* [prometheus-failed-compactions.md](prometheus-failed-compactions.md)
* [redis_latency.md](redis_latency.md)
* [redis_monitoring.md](redis_monitoring.md)
* [sentry-is-down.md](sentry-is-down.md)
* [version-gitlab-com.md](version-gitlab-com.md)
<!-- END_MARKER -->

<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Psql-timings Service

* **Responsible Teams**:
  * [infrastructure-database](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#ongres-gitlab](https://gitlab.slack.com/archives/ongres-gitlab)
  * [infrastructure-observability](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#observability](https://gitlab.slack.com/archives/observability)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=psql-timings&orgId=1
* **Alerts**: https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22psql-timings%22%2C%20tier%3D%22inf%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:PsqlTimings"

## Logging

* [PostgreSQL](/var/log/postgresql/postgresql-9.5-main.log)

<!-- END_MARKER -->

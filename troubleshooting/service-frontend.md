<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Frontend Service

* **Responsible Teams**:
  * [infrastructure-coreinfra](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
  * [infrastructure-webapp](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
  * [infrastructure-git](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=frontend&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22frontend%22%2C%20tier%3D%22lb%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:HAProxy"

## Logging

* [haproxy](https://console.cloud.google.com/logs/viewer?project=gitlab-production&organizationId=769164969568&interval=PT1H&resource=gce_instance%2Finstance_id%2F1812745190666049211&scrollTimestamp=2019-01-22T15:27:18.915253748Z&advancedFilter=resource.type%3D%22gce_instance%22%0Alabels.tag%3D%22haproxy%22)

## Troubleshooting Pointers

* [gitaly-latency.md](gitaly-latency.md)
* [gitaly-permission-denied.md](gitaly-permission-denied.md)
* [gitlab-registry.md](gitlab-registry.md)
* [haproxy.md](haproxy.md)
* [sentry-is-down.md](sentry-is-down.md)
<!-- END_MARKER -->

<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Contributors Service

* **Responsible Teams**:
  * [verify](https://about.gitlab.com/handbook/engineering/ops-backend/verify/). **Slack Channel**: [#g_verify](https://gitlab.slack.com/archives/g_verify)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=contributors&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22contributors%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Contributors"

## Logging

* [Rails](/home/contributors/app/log/production.log)

## Troubleshooting Pointers

* [../uncategorized/k8s-gitlab-operations.md](../uncategorized/k8s-gitlab-operations.md)
<!-- END_MARKER -->

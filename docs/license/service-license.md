<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  License Service

* **Responsible Teams**:
  * [infrastructure-businessops](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=license&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22license%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:License"

## Logging

* [production.log](/home/gitlab-license/license-gitlab-com/log/)

## Troubleshooting Pointers

* [../uncategorized/cloudsql-data-export.md](../uncategorized/cloudsql-data-export.md)
* [../uncategorized/yubikey.md](../uncategorized/yubikey.md)
<!-- END_MARKER -->

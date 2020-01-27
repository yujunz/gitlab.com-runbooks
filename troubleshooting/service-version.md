<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Version Service

* **Responsible Teams**:
  * [infrastructure-businessops](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=version&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22version%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Version"

## Logging

* [production.log](/var/log/version/)

## Troubleshooting Pointers

* [filesystem_alerts_inodes.md](filesystem_alerts_inodes.md)
* [gitaly-error-rate.md](gitaly-error-rate.md)
* [gitaly-version-mismatch.md](gitaly-version-mismatch.md)
* [omnibus-package-updates.md](omnibus-package-updates.md)
* [version-gitlab-com.md](version-gitlab-com.md)
<!-- END_MARKER -->

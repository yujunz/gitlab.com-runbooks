<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Forum Service

* **Responsible Teams**:
  * [support](https://about.gitlab.com/handbook/support/). **Slack Channel**: [#support_gitlab-com](https://gitlab.slack.com/archives/support_gitlab-com)
  * [infrastructure-businessops](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=forum&orgId=1
* **Alerts**: https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22forum%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"forum.gitlab.com"

## Logging

* [production.log](/var/discourse/shared/standalone/log/rails)

## Troubleshooting Pointers

* [discourse-forum.md](discourse-forum.md)
<!-- END_MARKER -->

<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Praefect Service

* **Responsible Teams**:
  * [gitaly](https://about.gitlab.com/handbook/engineering/dev-backend/gitaly/). **Slack Channel**: [#gitaly](https://gitlab.slack.com/archives/gitaly)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=praefect&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22praefect%22%2C%20tier%3D%22stor%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Praefect"

## Logging

* [system](https://log.gprd.gitlab.net/goto/769b1e96dc189470332cd7005dd6f878)

## Troubleshooting Pointers

* [../gitaly/praefect-file-storages.md](../gitaly/praefect-file-storages.md)
* [praefect-error-rate.md](praefect-error-rate.md)
* [praefect-startup.md](praefect-startup.md)
<!-- END_MARKER -->

## How To...

* [Add and remove file storages to praefect](../gitaly/praefect-file-storages.md)

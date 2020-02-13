<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Pgbouncer Service

* **Responsible Teams**:
  * [infrastructure-webapp](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
  * [infrastructure-database](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#ongres-gitlab](https://gitlab.slack.com/archives/ongres-gitlab)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=pgbouncer&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22pgbouncer%22%2C%20tier%3D%22db%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:pgbouncer"

## Logging

* [pgbouncer](https://log.gprd.gitlab.net/goto/3fb9391e5ef07b47aac2fce6fda175d9)
* [system](https://log.gprd.gitlab.net/goto/ae311f6f133cc1c45b62541977081043)

## Troubleshooting Pointers

* [gitlab-com-is-down.md](gitlab-com-is-down.md)
* [large-pull-mirror-queue.md](large-pull-mirror-queue.md)
* [pgbouncer.md](pgbouncer.md)
* [postgres.md](postgres.md)
<!-- END_MARKER -->

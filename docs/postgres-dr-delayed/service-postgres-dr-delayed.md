<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Postgres-dr-delayed Service

* **Responsible Teams**:
  * [infrastructure-database](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#ongres-gitlab](https://gitlab.slack.com/archives/ongres-gitlab)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=postgres-dr-delayed&orgId=1
* **Alerts**: https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22postgres-dr-delayed%22%2C%20tier%3D%22db%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:PostgresDelayed"

## Logging

* [system](https://log.gprd.gitlab.net/goto/3fea946a232d2288e90e575c912fa3e7)

## Troubleshooting Pointers

* [../patroni/patroni-management.md](../patroni/patroni-management.md)
* [../postgres-dr-archive/postgres-dr-replicas.md](../postgres-dr-archive/postgres-dr-replicas.md)
* [postgres-dr-replicas.md](postgres-dr-replicas.md)
<!-- END_MARKER -->

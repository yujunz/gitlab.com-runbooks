<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Patroni Service

* **Responsible Teams**:
  * [infrastructure-database](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#ongres-gitlab](https://gitlab.slack.com/archives/ongres-gitlab)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=patroni&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22patroni%22%2C%20tier%3D%22db%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Postgres"

## Logging

* [Postgres](https://log.gprd.gitlab.net/goto/d0f8993486c9007a69d85e3a08f1ea7c)
* [system](https://log.gprd.gitlab.net/goto/3669d551a595a3a5cf1e9318b74e6c22)

## Troubleshooting Pointers

* [../ci-runners/tracing-app-db-queries.md](../ci-runners/tracing-app-db-queries.md)
* [../monitoring/prometheus-failing-rule-evaluations.md](../monitoring/prometheus-failing-rule-evaluations.md)
* [geo-patroni-cluster.md](geo-patroni-cluster.md)
* [gitlab-com-wale-backups.md](gitlab-com-wale-backups.md)
* [gitlab-com-walg-backups.md](gitlab-com-walg-backups.md)
* [patroni-management.md](patroni-management.md)
* [pg-ha.md](pg-ha.md)
* [postgres.md](postgres.md)
* [postgresql-disk-space.md](postgresql-disk-space.md)
* [postgresql-replica.md](postgresql-replica.md)
* [postgresql.md](postgresql.md)
* [../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md](../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md)
<!-- END_MARKER -->
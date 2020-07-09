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

* [../frontend/gitlab-com-is-down.md](../frontend/gitlab-com-is-down.md)
* [../logging/README.md](../logging/README.md)
* [../patroni/patroni-management.md](../patroni/patroni-management.md)
* [../patroni/pg-ha.md](../patroni/pg-ha.md)
* [../patroni/postgres.md](../patroni/postgres.md)
* [../patroni/rotating-rails-postgresql-password.md](../patroni/rotating-rails-postgresql-password.md)
* [../patroni/user_grants_permission.md](../patroni/user_grants_permission.md)
* [README.md](README.md)
* [patroni-consul-postgres-pgbouncer-interactions.md](patroni-consul-postgres-pgbouncer-interactions.md)
* [pgbouncer-add-instance.md](pgbouncer-add-instance.md)
* [pgbouncer-applications.md](pgbouncer-applications.md)
* [pgbouncer-connections.md](pgbouncer-connections.md)
* [pgbouncer-remove-instance.md](pgbouncer-remove-instance.md)
* [pgbouncer-saturation.md](pgbouncer-saturation.md)
* [../sidekiq/large-pull-mirror-queue.md](../sidekiq/large-pull-mirror-queue.md)
<!-- END_MARKER -->

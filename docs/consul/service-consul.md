<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Consul Service

* **Responsible Teams**:
  * [infrastructure-coreinfra](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=consul&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22consul%22%2C%20tier%3D%22inf%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Consul"

## Logging

* [Consul](https://log.gprd.gitlab.net/goto/7f15b1f04a0f09fbb18fc62adefe3ed1)
* [system](https://log.gprd.gitlab.net/goto/a22fbb60e45a3f6d7860908a5427301c)

## Troubleshooting Pointers

* [../patroni/geo-patroni-cluster.md](../patroni/geo-patroni-cluster.md)
* [../patroni/patroni-management.md](../patroni/patroni-management.md)
* [../patroni/pg-ha.md](../patroni/pg-ha.md)
* [../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md](../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md)
* [../pgbouncer/pgbouncer-1.md](../pgbouncer/pgbouncer-1.md)
<!-- END_MARKER -->

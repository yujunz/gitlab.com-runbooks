<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Monitoring Service

* **Responsible Teams**:
  * [infrastructure-observability](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#observability](https://gitlab.slack.com/archives/observability)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=monitoring&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22monitoring%22%2C%20tier%3D%22inf%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Prometheus"

## Logging

* [system](https://log.gprd.gitlab.net/goto/3a0b51d10d33c9558765e97640acb325)

## Troubleshooting Pointers

* [../elastic/README.md](../elastic/README.md)
* [../elastic/elasticsearch-integration-in-gitlab.md](../elastic/elasticsearch-integration-in-gitlab.md)
* [../license/license-gitlab-com.md](../license/license-gitlab-com.md)
* [../logging/README.md](../logging/README.md)
* [alerts_gke.md](alerts_gke.md)
* [alerts_manual.md](alerts_manual.md)
* [monitoring-overview.md](monitoring-overview.md)
* [prometheus-failed-compactions.md](prometheus-failed-compactions.md)
* [sentry-is-down.md](sentry-is-down.md)
* [../patroni/postgres.md](../patroni/postgres.md)
* [../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md](../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md)
* [../redis/redis.md](../redis/redis.md)
* [../uncategorized/access-gcp-hosts.md](../uncategorized/access-gcp-hosts.md)
* [../uncategorized/job_completion.md](../uncategorized/job_completion.md)
* [../uncategorized/k8s-gitlab-operations.md](../uncategorized/k8s-gitlab-operations.md)
* [../uncategorized/k8s-gitlab.md](../uncategorized/k8s-gitlab.md)
* [../uncategorized/k8s-plantuml-operations.md](../uncategorized/k8s-plantuml-operations.md)
* [../uncategorized/packagecloud-infrastructure.md](../uncategorized/packagecloud-infrastructure.md)
* [../uncategorized/subnet-allocations.md](../uncategorized/subnet-allocations.md)
* [../uncategorized/upgrade-docker-machine.md](../uncategorized/upgrade-docker-machine.md)
* [../version/version-gitlab-com.md](../version/version-gitlab-com.md)
<!-- END_MARKER -->

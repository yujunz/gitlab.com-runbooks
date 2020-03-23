<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Stackdriver Service

* **Responsible Teams**:
  * [infrastructure-observability](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#observability](https://gitlab.slack.com/archives/observability)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=stackdriver&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22stackdriver%22%2C%20tier%3D%22inf%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Stackdriver"

## Logging

* []()

## Troubleshooting Pointers

* [../frontend/haproxy.md](../frontend/haproxy.md)
* [../gitaly/gitaly-down.md](../gitaly/gitaly-down.md)
* [../pgbouncer/pgbouncer.md](../pgbouncer/pgbouncer.md)
* [../pubsub/pubsub-queing.md](../pubsub/pubsub-queing.md)
* [../uncategorized/k8s-gitlab.md](../uncategorized/k8s-gitlab.md)
* [../uncategorized/kubernetes.md](../uncategorized/kubernetes.md)
* [../uncategorized/node-reboots.md](../uncategorized/node-reboots.md)
* [../version/version-gitlab-com.md](../version/version-gitlab-com.md)
<!-- END_MARKER -->
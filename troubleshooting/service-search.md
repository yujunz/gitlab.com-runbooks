<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Search Service

* **Responsible Teams**:
  * [infrastructure-observability](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#observability](https://gitlab.slack.com/archives/observability)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=search&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22search%22%2C%20tier%3D%22inf%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Elasticsearch"

## Logging

* [elastic stack monitoring](https://00a4ef3362214c44a044feaa539b4686.us-central1.gcp.cloud.es.io:9243/app/monitoring#/overview?_g=(cluster_uuid:D31oWYIkTUWCDPHigrPwHg))

## Troubleshooting Pointers

* [camoproxy.md](camoproxy.md)
* [chef.md](chef.md)
* [gitaly-permission-denied.md](gitaly-permission-denied.md)
* [gitaly-unusual-activity.md](gitaly-unusual-activity.md)
* [gitlab-pages.md](gitlab-pages.md)
* [kubernetes.md](kubernetes.md)
* [large-sidekiq-queue.md](large-sidekiq-queue.md)
* [node-reboots.md](node-reboots.md)
* [praefect-error-rate.md](praefect-error-rate.md)
* [sidekiq_error_rate_high.md](sidekiq_error_rate_high.md)
<!-- END_MARKER -->

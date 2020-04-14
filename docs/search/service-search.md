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

* [../ci-runners/ci-investigate-abuse.md](../ci-runners/ci-investigate-abuse.md)
* [../gitaly/find-project-from-hashed-storage.md](../gitaly/find-project-from-hashed-storage.md)
* [../gitaly/gitaly-permission-denied.md](../gitaly/gitaly-permission-denied.md)
* [../gitaly/gitaly-unusual-activity.md](../gitaly/gitaly-unusual-activity.md)
* [../gitaly/storage-rebalancing.md](../gitaly/storage-rebalancing.md)
* [../pages/gitlab-pages.md](../pages/gitlab-pages.md)
* [../praefect/praefect-error-rate.md](../praefect/praefect-error-rate.md)
* [../runner/ci-runner-timeouts.md](../runner/ci-runner-timeouts.md)
* [../runner/update-gitlab-runner-on-managers.md](../runner/update-gitlab-runner-on-managers.md)
* [../sidekiq/large-sidekiq-queue.md](../sidekiq/large-sidekiq-queue.md)
* [../sidekiq/sidekiq_error_rate_high.md](../sidekiq/sidekiq_error_rate_high.md)
* [../uncategorized/camoproxy.md](../uncategorized/camoproxy.md)
* [../uncategorized/chef-documentation.md](../uncategorized/chef-documentation.md)
* [../uncategorized/chef-guidelines.md](../uncategorized/chef-guidelines.md)
* [../uncategorized/chef.md](../uncategorized/chef.md)
* [../uncategorized/domain-registration.md](../uncategorized/domain-registration.md)
* [../uncategorized/gcp-snapshots.md](../uncategorized/gcp-snapshots.md)
* [../uncategorized/kubernetes.md](../uncategorized/kubernetes.md)
* [../uncategorized/manage-chef.md](../uncategorized/manage-chef.md)
* [../uncategorized/node-reboots.md](../uncategorized/node-reboots.md)
* [../uncategorized/uploads.md](../uncategorized/uploads.md)
* [../waf/cloudflare.md](../waf/cloudflare.md)
<!-- END_MARKER -->

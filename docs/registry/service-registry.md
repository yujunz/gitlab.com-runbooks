<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Registry Service

* **Responsible Teams**:
  * [package](https://about.gitlab.com/handbook/engineering/dev-backend/). **Slack Channel**: [#backend](https://gitlab.slack.com/archives/backend)
  * [infrastructure-caches-ci-queues](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=registry&orgId=1
* **Alerts**: https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22registry%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Registry"

## Logging

* [Registry](https://log.gprd.gitlab.net/goto/1c2fe46c1db40a7aa7d31875f3fd2ad1)
* [haproxy](https://console.cloud.google.com/logs/viewer?project=gitlab-production&interval=PT1H&resource=gce_instance&customFacets=labels.%22compute.googleapis.com%2Fresource_name%22&advancedFilter=labels.tag%3D%22haproxy%22%0Alabels.%22compute.googleapis.com%2Fresource_name%22%3A%22fe-registry-%22)
* [system](https://log.gprd.gitlab.net/goto/b68e1a4183a652dc8d5e52a1fc2c1aba)

## Troubleshooting Pointers

* [../ci-runners/create-runners-manager-node.md](../ci-runners/create-runners-manager-node.md)
* [../ci-runners/runners-cache.md](../ci-runners/runners-cache.md)
* [../ci-runners/runners_cache_disk_space.md](../ci-runners/runners_cache_disk_space.md)
* [../ci-runners/runners_cache_is_down.md](../ci-runners/runners_cache_is_down.md)
* [../ci-runners/runners_registry_is_down.md](../ci-runners/runners_registry_is_down.md)
* [../cloudflare/managing-traffic.md](../cloudflare/managing-traffic.md)
* [../frontend/haproxy.md](../frontend/haproxy.md)
* [../logging/README.md](../logging/README.md)
* [gitlab-registry.md](gitlab-registry.md)
* [../uncategorized/delete-projects-manually.md](../uncategorized/delete-projects-manually.md)
* [../uncategorized/k8s-gitlab-operations.md](../uncategorized/k8s-gitlab-operations.md)
* [../uncategorized/k8s-gitlab.md](../uncategorized/k8s-gitlab.md)
* [../uncategorized/k8s-operations.md](../uncategorized/k8s-operations.md)
* [../uncategorized/kubernetes.md](../uncategorized/kubernetes.md)
* [../uncategorized/tweeting-guidelines.md](../uncategorized/tweeting-guidelines.md)
<!-- END_MARKER -->

<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Pages Service

* **Responsible Teams**:
  * [infrastructure-webapp](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
  * [release-management](https://about.gitlab.com/handbook/engineering/development/ci-cd/release/release-management/). **Slack Channel**: [#g_release_management](https://gitlab.slack.com/archives/g_release_management)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=pages&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22pages%22%2C%20tier%3D%22lb%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Pages"

## Logging

* [Stackdriver Logs](https://console.cloud.google.com/logs/viewer?project=gitlab-production&advancedFilter=resource.type%3D%22gce_instance%22%0Alabels.tag%3D%22haproxy%22%0Alabels.%22compute.googleapis.com%2Fresource_name%22:%22fe-pages%22)

## Troubleshooting Pointers

* [../cloudflare/managing-traffic.md](../cloudflare/managing-traffic.md)
* [../frontend/haproxy.md](../frontend/haproxy.md)
* [../gitaly/gitaly-unusual-activity.md](../gitaly/gitaly-unusual-activity.md)
* [../logging/README.md](../logging/README.md)
* [../monitoring/node_memory_alerts.md](../monitoring/node_memory_alerts.md)
* [gitlab-pages.md](gitlab-pages.md)
* [pages-letsencrypt.md](pages-letsencrypt.md)
* [../uncategorized/chef-vault.md](../uncategorized/chef-vault.md)
* [../uncategorized/chef.md](../uncategorized/chef.md)
* [../uncategorized/deploycmd.md](../uncategorized/deploycmd.md)
<!-- END_MARKER -->

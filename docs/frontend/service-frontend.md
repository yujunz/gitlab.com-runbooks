<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Frontend Service

* **Responsible Teams**:
  * [infrastructure-coreinfra](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
  * [infrastructure-webapp](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
  * [infrastructure-git](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=frontend&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22frontend%22%2C%20tier%3D%22lb%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:HAProxy"

## Logging

* [haproxy](https://console.cloud.google.com/logs/viewer?project=gitlab-production&organizationId=769164969568&interval=PT1H&resource=gce_instance%2Finstance_id%2F1812745190666049211&scrollTimestamp=2019-01-22T15:27:18.915253748Z&advancedFilter=resource.type%3D%22gce_instance%22%0Alabels.tag%3D%22haproxy%22)

## Troubleshooting Pointers

* [haproxy.md](haproxy.md)
* [../git/deploy-gitlab-rb-change.md](../git/deploy-gitlab-rb-change.md)
* [../git/gitlab-hosted-codesandbox.md](../git/gitlab-hosted-codesandbox.md)
* [../gitaly/gitaly-latency.md](../gitaly/gitaly-latency.md)
* [../gitaly/gitaly-permission-denied.md](../gitaly/gitaly-permission-denied.md)
* [../monitoring/sentry-is-down.md](../monitoring/sentry-is-down.md)
* [../pgbouncer/README.md](../pgbouncer/README.md)
* [../registry/gitlab-registry.md](../registry/gitlab-registry.md)
* [../uncategorized/alert-for-ssl-certificate-expiration.md](../uncategorized/alert-for-ssl-certificate-expiration.md)
* [../uncategorized/chef-guidelines.md](../uncategorized/chef-guidelines.md)
* [../uncategorized/manage-workers.md](../uncategorized/manage-workers.md)
<!-- END_MARKER -->

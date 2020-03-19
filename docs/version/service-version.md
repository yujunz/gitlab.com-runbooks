<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Version Service

* **Responsible Teams**:
  * [infrastructure-businessops](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=version&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22version%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Version"

## Logging

* [production.log](/var/log/version/)

## Troubleshooting Pointers

* [../gitaly/gitaly-error-rate.md](../gitaly/gitaly-error-rate.md)
* [../gitaly/storage-sharding.md](../gitaly/storage-sharding.md)
* [../monitoring/filesystem_alerts_inodes.md](../monitoring/filesystem_alerts_inodes.md)
* [../monitoring/update-prometheus-and-exporters.md](../monitoring/update-prometheus-and-exporters.md)
* [../patroni/patroni-management.md](../patroni/patroni-management.md)
* [../patroni/using-wale-gpg.md](../patroni/using-wale-gpg.md)
* [../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md](../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md)
* [../runner/update-gitlab-runner-on-managers.md](../runner/update-gitlab-runner-on-managers.md)
* [../uncategorized/about-gitlab-com.md](../uncategorized/about-gitlab-com.md)
* [../uncategorized/aptly.md](../uncategorized/aptly.md)
* [../uncategorized/chef-documentation.md](../uncategorized/chef-documentation.md)
* [../uncategorized/chef-guidelines.md](../uncategorized/chef-guidelines.md)
* [../uncategorized/chef-vault.md](../uncategorized/chef-vault.md)
* [../uncategorized/chefspec.md](../uncategorized/chefspec.md)
* [../uncategorized/cloudsql-data-export.md](../uncategorized/cloudsql-data-export.md)
* [../uncategorized/dev-environment.md](../uncategorized/dev-environment.md)
* [../uncategorized/k8s-cluster-upgrade.md](../uncategorized/k8s-cluster-upgrade.md)
* [../uncategorized/k8s-gitlab-operations.md](../uncategorized/k8s-gitlab-operations.md)
* [../uncategorized/k8s-operations.md](../uncategorized/k8s-operations.md)
* [../uncategorized/k8s-plantuml-operations.md](../uncategorized/k8s-plantuml-operations.md)
* [../uncategorized/manage-chef.md](../uncategorized/manage-chef.md)
* [../uncategorized/manage-pacemaker.md](../uncategorized/manage-pacemaker.md)
* [../uncategorized/manage-package-signing-keys.md](../uncategorized/manage-package-signing-keys.md)
* [../uncategorized/manage-workers.md](../uncategorized/manage-workers.md)
* [../uncategorized/mtail.md](../uncategorized/mtail.md)
* [../uncategorized/omnibus-package-updates.md](../uncategorized/omnibus-package-updates.md)
* [../uncategorized/remove-kernels.md](../uncategorized/remove-kernels.md)
* [../uncategorized/tweeting-guidelines.md](../uncategorized/tweeting-guidelines.md)
* [../uncategorized/upgrade-camoproxy.md](../uncategorized/upgrade-camoproxy.md)
* [../uncategorized/upgrade-docker-machine.md](../uncategorized/upgrade-docker-machine.md)
* [../uncategorized/uptycs_osquery.md](../uncategorized/uptycs_osquery.md)
* [../uncategorized/yubikey.md](../uncategorized/yubikey.md)
* [gitaly-version-mismatch.md](gitaly-version-mismatch.md)
* [version-gitlab-com.md](version-gitlab-com.md)
* [../web/static-repository-objects-caching.md](../web/static-repository-objects-caching.md)
<!-- END_MARKER -->

<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Console Service

* **Responsible Teams**:
  * [infrastructure-coreinfra](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
  * [infrastructure-webapp](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
  * [infrastructure-caches-ci-queues](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=console&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22console%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Console"

## Logging

* [history]()
* []()

## Troubleshooting Pointers

* [../frontend/haproxy-1.md](../frontend/haproxy-1.md)
* [../frontend/haproxy.md](../frontend/haproxy.md)
* [../git/purge-git-data.md](../git/purge-git-data.md)
* [../gitaly/find-project-from-hashed-storage.md](../gitaly/find-project-from-hashed-storage.md)
* [../gitaly/gitaly-down.md](../gitaly/gitaly-down.md)
* [../gitaly/gitaly-token-rotation.md](../gitaly/gitaly-token-rotation.md)
* [../gitaly/storage-rebalancing.md](../gitaly/storage-rebalancing.md)
* [../monitoring/filesystem_alerts.md](../monitoring/filesystem_alerts.md)
* [../pages/pages-letsencrypt.md](../pages/pages-letsencrypt.md)
* [../patroni/gitlab-com-wale-backups.md](../patroni/gitlab-com-wale-backups.md)
* [../patroni/patroni-management.md](../patroni/patroni-management.md)
* [../patroni/pg-ha.md](../patroni/pg-ha.md)
* [../patroni/postgres-backup-verification-failures.md](../patroni/postgres-backup-verification-failures.md)
* [../patroni/postgres.md](../patroni/postgres.md)
* [../patroni/using-wale-gpg.md](../patroni/using-wale-gpg.md)
* [../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md](../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md)
* [../pgbouncer/pgbouncer-1.md](../pgbouncer/pgbouncer-1.md)
* [../pgbouncer/pgbouncer.md](../pgbouncer/pgbouncer.md)
* [../redis/clear_anonymous_sessions.md](../redis/clear_anonymous_sessions.md)
* [../redis/redis.md](../redis/redis.md)
* [../registry/gitlab-registry.md](../registry/gitlab-registry.md)
* [../sidekiq/large-sidekiq-queue.md](../sidekiq/large-sidekiq-queue.md)
* [../sidekiq/sidekiq-inspection.md](../sidekiq/sidekiq-inspection.md)
* [../sidekiq/sidekiq_error_rate_high.md](../sidekiq/sidekiq_error_rate_high.md)
* [../sidekiq/sidekiq_stats_no_longer_showing.md](../sidekiq/sidekiq_stats_no_longer_showing.md)
* [../sidekiq/silent-project-exports.md](../sidekiq/silent-project-exports.md)
* [../uncategorized/about-gitlab-com.md](../uncategorized/about-gitlab-com.md)
* [../uncategorized/block-high-load-project.md](../uncategorized/block-high-load-project.md)
* [../uncategorized/debug-failed-chef-provisioning.md](../uncategorized/debug-failed-chef-provisioning.md)
* [../uncategorized/delete-projects-manually.md](../uncategorized/delete-projects-manually.md)
* [../uncategorized/deleted-project-restore.md](../uncategorized/deleted-project-restore.md)
* [../uncategorized/domain-registration.md](../uncategorized/domain-registration.md)
* [../uncategorized/dr-bastions.md](../uncategorized/dr-bastions.md)
* [../uncategorized/gcloud-cli.md](../uncategorized/gcloud-cli.md)
* [../uncategorized/gemnasium_is_down.md](../uncategorized/gemnasium_is_down.md)
* [../uncategorized/geo-recover-repo-from-azure.md](../uncategorized/geo-recover-repo-from-azure.md)
* [../uncategorized/gprd-bastions.md](../uncategorized/gprd-bastions.md)
* [../uncategorized/granting-rails-or-db-access.md](../uncategorized/granting-rails-or-db-access.md)
* [../uncategorized/gstg-bastions.md](../uncategorized/gstg-bastions.md)
* [../uncategorized/k8s-cluster-upgrade.md](../uncategorized/k8s-cluster-upgrade.md)
* [../uncategorized/k8s-gitlab-operations.md](../uncategorized/k8s-gitlab-operations.md)
* [../uncategorized/k8s-operations.md](../uncategorized/k8s-operations.md)
* [../uncategorized/k8s-plantuml-operations.md](../uncategorized/k8s-plantuml-operations.md)
* [../uncategorized/kubernetes.md](../uncategorized/kubernetes.md)
* [../uncategorized/manage-cog.md](../uncategorized/manage-cog.md)
* [../uncategorized/missing_repos.md](../uncategorized/missing_repos.md)
* [../uncategorized/pre-bastions.md](../uncategorized/pre-bastions.md)
* [../uncategorized/reindex-package-in-packagecloud.md](../uncategorized/reindex-package-in-packagecloud.md)
* [../uncategorized/staging-environment.md](../uncategorized/staging-environment.md)
* [../uncategorized/testbed-bastion.md](../uncategorized/testbed-bastion.md)
* [../uncategorized/uploads.md](../uncategorized/uploads.md)
* [../uncategorized/workers-high-load.md](../uncategorized/workers-high-load.md)
* [../version/version-gitlab-com.md](../version/version-gitlab-com.md)
<!-- END_MARKER -->

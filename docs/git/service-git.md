<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Git Service

* **Responsible Teams**:
  * [create](https://about.gitlab.com/handbook/engineering/dev-backend/create/). **Slack Channel**: [#g_create](https://gitlab.slack.com/archives/g_create)
  * [distribution](https://about.gitlab.com/handbook/engineering/dev-backend/distribution/). **Slack Channel**: [#distribution](https://gitlab.slack.com/archives/distribution)
  * [geo](https://about.gitlab.com/handbook/engineering/dev-backend/geo/). **Slack Channel**: [#g_geo](https://gitlab.slack.com/archives/g_geo)
  * [gitaly](https://about.gitlab.com/handbook/engineering/dev-backend/gitaly/). **Slack Channel**: [#gitaly](https://gitlab.slack.com/archives/gitaly)
  * [gitter](https://about.gitlab.com/handbook/engineering/dev-backend/gitter/). **Slack Channel**: [#g_gitaly](https://gitlab.slack.com/archives/g_gitaly)
  * [manage](https://about.gitlab.com/handbook/engineering/dev-backend/manage/). **Slack Channel**: [#g_manage](https://gitlab.slack.com/archives/g_manage)
  * [plan](https://about.gitlab.com/handbook/engineering/dev-backend/manage/). **Slack Channel**: [#g_plan](https://gitlab.slack.com/archives/g_plan)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=git&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22git%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Git"

## Logging

* [Rails](https://log.gprd.gitlab.net/goto/b368513b02f183a06d28c2a958b00602)
* [Workhorse](https://log.gprd.gitlab.net/goto/3ddd4ee7141ba2ec1a8b3bb0cb1476fe)
* [Unicorn](https://log.gprd.gitlab.net/goto/0cf60e9a1c94236eefb23348c39feaeb)
* [nginx](https://log.gprd.gitlab.net/goto/8a5fb5820ec7c8daebf719c51fa00ce0)
* [Unstructured Rails](https://console.cloud.google.com/logs/viewer?project=gitlab-production&interval=PT1H&resource=gce_instance&advancedFilter=jsonPayload.hostname%3A%22git%22%0Alabels.tag%3D%22unstructured.production%22&customFacets=labels.%22compute.googleapis.com%2Fresource_name%22)
* [system](https://log.gprd.gitlab.net/goto/bd680ccb3c21567e47a821bbf52a7c09)

## Troubleshooting Pointers

* [../blackbox/blackbox-git-exporter.md](../blackbox/blackbox-git-exporter.md)
* [../ci-runners/ci-investigate-abuse.md](../ci-runners/ci-investigate-abuse.md)
* [../ci-runners/load-balancing.md](../ci-runners/load-balancing.md)
* [../forum/discourse-forum.md](../forum/discourse-forum.md)
* [../frontend/block-things-in-haproxy.md](../frontend/block-things-in-haproxy.md)
* [../frontend/haproxy-1.md](../frontend/haproxy-1.md)
* [../frontend/haproxy.md](../frontend/haproxy.md)
* [../frontend/ssh-maxstartups-breach.md](../frontend/ssh-maxstartups-breach.md)
* [deploy-gitlab-rb-change.md](deploy-gitlab-rb-change.md)
* [git-stuck-processes.md](git-stuck-processes.md)
* [git.md](git.md)
* [purge-git-data.md](purge-git-data.md)
* [workhorse-git-session-alerts.md](workhorse-git-session-alerts.md)
* [../gitaly/find-project-from-hashed-storage.md](../gitaly/find-project-from-hashed-storage.md)
* [../gitaly/gitaly-debugging-tool.md](../gitaly/gitaly-debugging-tool.md)
* [../gitaly/gitaly-down.md](../gitaly/gitaly-down.md)
* [../gitaly/gitaly-latency.md](../gitaly/gitaly-latency.md)
* [../gitaly/gitaly-rate-limiting.md](../gitaly/gitaly-rate-limiting.md)
* [../gitaly/storage-rebalancing.md](../gitaly/storage-rebalancing.md)
* [../gitaly/storage-servers.md](../gitaly/storage-servers.md)
* [../gitaly/storage-sharding.md](../gitaly/storage-sharding.md)
* [../monitoring/alerts_manual.md](../monitoring/alerts_manual.md)
* [../monitoring/monitoring-overview.md](../monitoring/monitoring-overview.md)
* [../nfs/recovering-from-nfs-disaster.md](../nfs/recovering-from-nfs-disaster.md)
* [../patroni/patroni-management.md](../patroni/patroni-management.md)
* [../runner/update-gitlab-runner-on-managers.md](../runner/update-gitlab-runner-on-managers.md)
* [../sidekiq/large-sidekiq-queue.md](../sidekiq/large-sidekiq-queue.md)
* [../sidekiq/silent-project-exports.md](../sidekiq/silent-project-exports.md)
* [../uncategorized/azure-snapshots.md](../uncategorized/azure-snapshots.md)
* [../uncategorized/blocked-user-logins.md](../uncategorized/blocked-user-logins.md)
* [../uncategorized/chef-documentation.md](../uncategorized/chef-documentation.md)
* [../uncategorized/chef-vault.md](../uncategorized/chef-vault.md)
* [../uncategorized/deleted-project-restore.md](../uncategorized/deleted-project-restore.md)
* [../uncategorized/dev-environment.md](../uncategorized/dev-environment.md)
* [../uncategorized/dr-bastions.md](../uncategorized/dr-bastions.md)
* [../uncategorized/geo-recover-repo-from-azure.md](../uncategorized/geo-recover-repo-from-azure.md)
* [../uncategorized/gprd-bastions.md](../uncategorized/gprd-bastions.md)
* [../uncategorized/granting-rails-or-db-access.md](../uncategorized/granting-rails-or-db-access.md)
* [../uncategorized/gstg-bastions.md](../uncategorized/gstg-bastions.md)
* [../uncategorized/k8s-operations.md](../uncategorized/k8s-operations.md)
* [../uncategorized/manage-workers.md](../uncategorized/manage-workers.md)
* [../uncategorized/missing_repos.md](../uncategorized/missing_repos.md)
* [../uncategorized/upload-file-to-gcs-using-signed-url.md](../uncategorized/upload-file-to-gcs-using-signed-url.md)
* [../uncategorized/workers-high-load.md](../uncategorized/workers-high-load.md)
* [../uncategorized/yubikey.md](../uncategorized/yubikey.md)
<!-- END_MARKER -->
<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Nfs Service

* **Responsible Teams**:
  * [infrastructure-webapp](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
  * [infrastructure-caches-ci-queues](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
  * [create](https://about.gitlab.com/handbook/engineering/dev-backend/create/). **Slack Channel**: [#g_create](https://gitlab.slack.com/archives/g_create)
  * [distribution](https://about.gitlab.com/handbook/engineering/dev-backend/distribution/). **Slack Channel**: [#distribution](https://gitlab.slack.com/archives/distribution)
  * [geo](https://about.gitlab.com/handbook/engineering/dev-backend/geo/). **Slack Channel**: [#g_geo](https://gitlab.slack.com/archives/g_geo)
  * [manage](https://about.gitlab.com/handbook/engineering/dev-backend/manage/). **Slack Channel**: [#g_manage](https://gitlab.slack.com/archives/g_manage)
  * [plan](https://about.gitlab.com/handbook/engineering/dev-backend/manage/). **Slack Channel**: [#g_plan](https://gitlab.slack.com/archives/g_plan)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=nfs&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22nfs%22%2C%20tier%3D%22stor%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Share"

## Logging

* [system](https://log.gprd.gitlab.net/goto/3a1a0019df2f6b555866b6f11eb92172)

## Troubleshooting Pointers

* [../blackbox/blackbox-git-exporter.md](../blackbox/blackbox-git-exporter.md)
* [../frontend/block-things-in-haproxy.md](../frontend/block-things-in-haproxy.md)
* [../gitaly/gitaly-down.md](../gitaly/gitaly-down.md)
* [../gitaly/gitaly-error-rate.md](../gitaly/gitaly-error-rate.md)
* [../gitaly/gracefully-restart-gitaly-ruby.md](../gitaly/gracefully-restart-gitaly-ruby.md)
* [../gitaly/storage-rebalancing.md](../gitaly/storage-rebalancing.md)
* [recovering-from-nfs-disaster.md](recovering-from-nfs-disaster.md)
* [../uncategorized/chef-guidelines.md](../uncategorized/chef-guidelines.md)
* [../uncategorized/deleted-project-restore.md](../uncategorized/deleted-project-restore.md)
* [../uncategorized/missing_repos.md](../uncategorized/missing_repos.md)
* [../uncategorized/stale-file-handles.md](../uncategorized/stale-file-handles.md)
<!-- END_MARKER -->

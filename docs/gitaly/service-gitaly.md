<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Gitaly Service

* **Responsible Teams**:
  * [gitaly](https://about.gitlab.com/handbook/engineering/dev-backend/gitaly/). **Slack Channel**: [#gitaly](https://gitlab.slack.com/archives/gitaly)
  * [infrastructure-git](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=gitaly&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22gitaly%22%2C%20tier%3D%22stor%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Gitaly"

## Logging

* [Gitaly](https://log.gprd.gitlab.net/goto/4f0bd7f08b264e7de970bb0cc9530f9d)
* [gitlab-shell](https://log.gprd.gitlab.net/goto/ba97a9597863f0df1c3b894b44eb1db6)
* [system](https://log.gprd.gitlab.net/goto/7cfb513706cffc0789ad0842674e108a)

## Troubleshooting Pointers

* [../git/deploy-gitlab-rb-change.md](../git/deploy-gitlab-rb-change.md)
* [../git/workhorse-git-session-alerts.md](../git/workhorse-git-session-alerts.md)
* [find-project-from-hashed-storage.md](find-project-from-hashed-storage.md)
* [gitaly-debugging-tool.md](gitaly-debugging-tool.md)
* [gitaly-down.md](gitaly-down.md)
* [gitaly-error-rate.md](gitaly-error-rate.md)
* [gitaly-latency.md](gitaly-latency.md)
* [gitaly-permission-denied.md](gitaly-permission-denied.md)
* [gitaly-profiling.md](gitaly-profiling.md)
* [gitaly-pubsub.md](gitaly-pubsub.md)
* [gitaly-rate-limiting.md](gitaly-rate-limiting.md)
* [gitaly-token-rotation.md](gitaly-token-rotation.md)
* [gitaly-unusual-activity.md](gitaly-unusual-activity.md)
* [gracefully-restart-gitaly-ruby.md](gracefully-restart-gitaly-ruby.md)
* [praefect-file-storages.md](praefect-file-storages.md)
* [storage-rebalancing.md](storage-rebalancing.md)
* [storage-servers.md](storage-servers.md)
* [storage-sharding.md](storage-sharding.md)
* [../praefect/praefect-error-rate.md](../praefect/praefect-error-rate.md)
* [../uncategorized/deleted-project-restore.md](../uncategorized/deleted-project-restore.md)
* [../uncategorized/pingdom.md](../uncategorized/pingdom.md)
* [../uncategorized/upload-file-to-gcs-using-signed-url.md](../uncategorized/upload-file-to-gcs-using-signed-url.md)
* [../version/gitaly-version-mismatch.md](../version/gitaly-version-mismatch.md)
<!-- END_MARKER -->
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

* [Rails](https://log.gitlab.net/goto/b368513b02f183a06d28c2a958b00602)
* [Workhorse](https://log.gitlab.net/goto/3ddd4ee7141ba2ec1a8b3bb0cb1476fe)
* [Unicorn](https://log.gitlab.net/goto/0cf60e9a1c94236eefb23348c39feaeb)
* [nginx](https://log.gitlab.net/goto/8a5fb5820ec7c8daebf719c51fa00ce0)
* [Unstructured Rails](https://console.cloud.google.com/logs/viewer?project=gitlab-production&interval=PT1H&resource=gce_instance&advancedFilter=jsonPayload.hostname%3A%22git%22%0Alabels.tag%3D%22unstructured.production%22&customFacets=labels.%22compute.googleapis.com%2Fresource_name%22)
* [system](https://log.gitlab.net/goto/bd680ccb3c21567e47a821bbf52a7c09)

## Troubleshooting Pointers

* [blackbox-git-exporter.md](blackbox-git-exporter.md)
* [blocked-user-logins.md](blocked-user-logins.md)
* [git-stuck-processes.md](git-stuck-processes.md)
* [git.md](git.md)
* [gitaly-down.md](gitaly-down.md)
* [gitaly-latency.md](gitaly-latency.md)
* [gitaly-rate-limiting.md](gitaly-rate-limiting.md)
* [haproxy.md](haproxy.md)
* [large-sidekiq-queue.md](large-sidekiq-queue.md)
* [missing_repos.md](missing_repos.md)
* [recovering-from-nfs-disaster.md](recovering-from-nfs-disaster.md)
* [ssh-maxstartups-breach.md](ssh-maxstartups-breach.md)
* [workers-high-load.md](workers-high-load.md)
* [workhorse-git-session-alerts.md](workhorse-git-session-alerts.md)
<!-- END_MARKER -->

<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Api Service

* **Responsible Teams**:
  * [create](https://about.gitlab.com/handbook/engineering/dev-backend/create/). **Slack Channel**: [#g_create](https://gitlab.slack.com/archives/g_create)
  * [distribution](https://about.gitlab.com/handbook/engineering/dev-backend/distribution/). **Slack Channel**: [#distribution](https://gitlab.slack.com/archives/distribution)
  * [geo](https://about.gitlab.com/handbook/engineering/dev-backend/geo/). **Slack Channel**: [#g_geo](https://gitlab.slack.com/archives/g_geo)
  * [gitaly](https://about.gitlab.com/handbook/engineering/dev-backend/gitaly/). **Slack Channel**: [#gitaly](https://gitlab.slack.com/archives/gitaly)
  * [gitter](https://about.gitlab.com/handbook/engineering/dev-backend/gitter/). **Slack Channel**: [#g_gitaly](https://gitlab.slack.com/archives/g_gitaly)
  * [manage](https://about.gitlab.com/handbook/engineering/dev-backend/manage/). **Slack Channel**: [#g_manage](https://gitlab.slack.com/archives/g_manage)
  * [plan](https://about.gitlab.com/handbook/engineering/dev-backend/manage/). **Slack Channel**: [#g_plan](https://gitlab.slack.com/archives/g_plan)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=api&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22api%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:API"

## Logging

* [Rails](https://log.gitlab.net/goto/0238ddb1480bb4bd19c09f0467b6e684)
* [Workhorse](https://log.gitlab.net/goto/eb99f28c17cfcdfd30969a1c85e209dc)
* [Unicorn](https://log.gitlab.net/goto/c8f89b2415788b46978fcd2910b4afec)
* [nginx](https://log.gitlab.net/goto/0d1c84486d6fb28a785f1c21473e5611)
* [Unstructured Rails](https://console.cloud.google.com/logs/viewer?project=gitlab-production&interval=PT1H&resource=gce_instance&advancedFilter=jsonPayload.hostname%3A%22api%22%0Alabels.tag%3D%22unstructured.production%22&customFacets=labels.%22compute.googleapis.com%2Fresource_name%22)
* [system](https://log.gitlab.net/goto/2b9679dab019791136cb8ae1535fb781)

## Troubleshooting Pointers

* [alertmanager-notification-failures.md](alertmanager-notification-failures.md)
* [blocked-user-logins.md](blocked-user-logins.md)
* [gemnasium_is_down.md](gemnasium_is_down.md)
* [haproxy.md](haproxy.md)
* [large-sidekiq-queue.md](large-sidekiq-queue.md)
* [pgbouncer.md](pgbouncer.md)
* [postgres.md](postgres.md)
* [ssh-maxstartups-breach.md](ssh-maxstartups-breach.md)
<!-- END_MARKER -->

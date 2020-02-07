<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Web Service

* **Responsible Teams**:
  * [create](https://about.gitlab.com/handbook/engineering/dev-backend/create/). **Slack Channel**: [#g_create](https://gitlab.slack.com/archives/g_create)
  * [distribution](https://about.gitlab.com/handbook/engineering/dev-backend/distribution/). **Slack Channel**: [#distribution](https://gitlab.slack.com/archives/distribution)
  * [geo](https://about.gitlab.com/handbook/engineering/dev-backend/geo/). **Slack Channel**: [#g_geo](https://gitlab.slack.com/archives/g_geo)
  * [gitaly](https://about.gitlab.com/handbook/engineering/dev-backend/gitaly/). **Slack Channel**: [#gitaly](https://gitlab.slack.com/archives/gitaly)
  * [gitter](https://about.gitlab.com/handbook/engineering/dev-backend/gitter/). **Slack Channel**: [#g_gitaly](https://gitlab.slack.com/archives/g_gitaly)
  * [manage](https://about.gitlab.com/handbook/engineering/dev-backend/manage/). **Slack Channel**: [#g_manage](https://gitlab.slack.com/archives/g_manage)
  * [plan](https://about.gitlab.com/handbook/engineering/dev-backend/manage/). **Slack Channel**: [#g_plan](https://gitlab.slack.com/archives/g_plan)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=web&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22web%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Web"

## Logging

* [Rails](https://log.gprd.gitlab.net/goto/5e1aa9dac377ff2282c70748e9278860)
* [Workhorse](https://log.gprd.gitlab.net/goto/cebefc3cf285ce2a94fbfdcadc55f1a4)
* [Unicorn](https://log.gprd.gitlab.net/goto/766f73d879983f5ec962d5d6c0ae1cf4)
* [nginx](https://log.gprd.gitlab.net/goto/4844ecfa4a7e6f0491685b2cc9224eb0)
* [Unstructured Rails](https://console.cloud.google.com/logs/viewer?project=gitlab-production&interval=PT1H&resource=gce_instance&advancedFilter=jsonPayload.hostname%3A%22web%22%0Alabels.tag%3D%22unstructured.production%22&customFacets=labels.%22compute.googleapis.com%2Fresource_name%22)
* [system](https://log.gprd.gitlab.net/goto/c93fb9b8e5df92ed79d993d3a62b5452)

## Troubleshooting Pointers

* [blocked-user-logins.md](blocked-user-logins.md)
* [debug-failed-chef-provisioning.md](debug-failed-chef-provisioning.md)
* [gemnasium_is_down.md](gemnasium_is_down.md)
* [gitaly-down.md](gitaly-down.md)
* [gitaly-latency.md](gitaly-latency.md)
* [gitlab-com-wale-backups.md](gitlab-com-wale-backups.md)
* [haproxy.md](haproxy.md)
* [pgbouncer.md](pgbouncer.md)
* [postgres.md](postgres.md)
* [recovering-from-nfs-disaster.md](recovering-from-nfs-disaster.md)
* [sentry-is-down.md](sentry-is-down.md)
<!-- END_MARKER -->

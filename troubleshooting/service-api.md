<!-- MARKER: do not edit this section directly. Edit services/service-mappings.yml then run scripts/generate-docs -->
#  Api Service

* **Responsible Team**: [backend](https://about.gitlab.com/handbook/engineering/dev-backend/)
* **Slack Channel**: [#backend](https://gitlab.slack.com/archives/backend)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/WOtyonOiz/general-triage-service?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=api&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22api%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:API"
* **Sentry**: https://sentry.gitlab.net/gitlab/gitlabcom/?query=program%3A%22rails%22

## Logging

* [Rails](https://log.gitlab.net/goto/0238ddb1480bb4bd19c09f0467b6e684)
* [Workhorse](https://log.gitlab.net/goto/eb99f28c17cfcdfd30969a1c85e209dc)
* [Unicorn](https://log.gitlab.net/goto/c8f89b2415788b46978fcd2910b4afec)
* [nginx](https://log.gitlab.net/goto/0d1c84486d6fb28a785f1c21473e5611)
* [Unstructured Rails](https://console.cloud.google.com/logs/viewer?project=gitlab-production&interval=PT1H&resource=gce_instance&advancedFilter=jsonPayload.hostname%3A%22api%22%0Alabels.tag%3D%22unstructured.production%22&customFacets=labels.%22compute.googleapis.com%2Fresource_name%22)
* [system](https://log.gitlab.net/goto/2b9679dab019791136cb8ae1535fb781)

## Troubleshooting Pointers

* [alertmanager-notification-failures.md](alertmanager-notification-failures.md)
* [ci_graphs.md](ci_graphs.md)
* [ci_introduction.md](ci_introduction.md)
* [ci_pending_builds.md](ci_pending_builds.md)
* [ci_runner_manager_errors.md](ci_runner_manager_errors.md)
* [gemnasium_is_down.md](gemnasium_is_down.md)
* [large-sidekiq-queue.md](large-sidekiq-queue.md)
* [postgres.md](postgres.md)
<!-- END_MARKER -->

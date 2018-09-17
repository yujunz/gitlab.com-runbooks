<!-- MARKER: do not edit this section directly. Edit services/service-mappings.yml then run scripts/generate-docs -->
#  Api Service

* **Responsible Team**: [backend](https://about.gitlab.com/handbook/engineering/dev-backend/)
* **Slack Channel**: [#backend](https://gitlab.slack.com/archives/backend)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/WOtyonOiz/general-triage-service?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=api&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22api%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com~"Service:API"
* **Sentry**: https://sentry.gitlap.com/gitlab/gitlabcom
* **ELK**: [`pubsub-rails-inf-gprd-*`](https://log.gitlab.net/goto/0238ddb1480bb4bd19c09f0467b6e684)

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

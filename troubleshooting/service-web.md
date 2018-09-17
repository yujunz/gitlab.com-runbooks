<!-- MARKER: do not edit this section directly. Edit services/service-mappings.yml then run scripts/generate-docs -->
#  Web Service

* **Responsible Team**: [backend](https://about.gitlab.com/handbook/engineering/dev-backend/)
* **Slack Channel**: [#backend](https://gitlab.slack.com/archives/production/backend)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/WOtyonOiz/general-triage-service?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=web&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22web%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com~"Service:Web"
* **Sentry**: https://sentry.gitlap.com/gitlab/gitlabcom
* **ELK**: [`pubsub-rails-inf-gprd-*`](https://log.gitlab.net/goto/5e1aa9dac377ff2282c70748e9278860)

## Troubleshooting Pointers

* [gemnasium_is_down.md](gemnasium_is_down.md)
* [gitaly-latency.md](gitaly-latency.md)
* [postgres.md](postgres.md)
* [recovering-from-nfs-disaster.md](recovering-from-nfs-disaster.md)
* [sentry-is-down.md](sentry-is-down.md)
<!-- END_MARKER -->

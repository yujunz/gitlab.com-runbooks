<!-- MARKER: do not edit this section directly. Edit services/service-mappings.yml then run scripts/generate-docs -->
#  Git Service

* **Responsible Team**: [backend](https://about.gitlab.com/handbook/engineering/dev-backend/)
* **Slack Channel**: [#backend](https://gitlab.slack.com/archives/production/backend)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/WOtyonOiz/general-triage-service?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=git&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22git%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com~"Service:GitLab Shell"
* **Sentry**: https://sentry.gitlap.com/gitlab/gitlabcom
* **ELK**: [`pubsub-rails-inf-gprd-*`](https://log.gitlab.net/goto/b368513b02f183a06d28c2a958b00602)

## Troubleshooting Pointers

* [blackbox-git-exporter.md](blackbox-git-exporter.md)
* [ci_introduction.md](ci_introduction.md)
* [ci_pending_builds.md](ci_pending_builds.md)
* [git-stuck-processes.md](git-stuck-processes.md)
* [git.md](git.md)
* [gitaly-high-cpu.md](gitaly-high-cpu.md)
* [large-sidekiq-queue.md](large-sidekiq-queue.md)
* [recovering-from-nfs-disaster.md](recovering-from-nfs-disaster.md)
* [workers-high-load.md](workers-high-load.md)
<!-- END_MARKER -->

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

* [gitaly-down.md](gitaly-down.md)
* [gitaly-error-rate.md](gitaly-error-rate.md)
* [gitaly-latency.md](gitaly-latency.md)
* [gitaly-permission-denied.md](gitaly-permission-denied.md)
* [gitaly-pubsub.md](gitaly-pubsub.md)
* [gitaly-rate-limiting.md](gitaly-rate-limiting.md)
* [gitaly-unusual-activity.md](gitaly-unusual-activity.md)
* [gitaly-version-mismatch.md](gitaly-version-mismatch.md)
* [praefect-error-rate.md](praefect-error-rate.md)
* [workhorse-git-session-alerts.md](workhorse-git-session-alerts.md)
<!-- END_MARKER -->

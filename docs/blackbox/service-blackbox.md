<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Blackbox Service

* **Responsible Teams**:
  * [infrastructure-observability](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#observability](https://gitlab.slack.com/archives/observability)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=blackbox&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22blackbox%22%2C%20tier%3D%22inf%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Blackbox"

## Logging

* [system](https://log.gprd.gitlab.net/goto/b4618f79f80f44cb21a32623a275a0e6)

## Troubleshooting Pointers

* [blackbox-git-exporter.md](blackbox-git-exporter.md)
* [../ci-runners/runners_cache_is_down.md](../ci-runners/runners_cache_is_down.md)
* [../patroni/postgres.md](../patroni/postgres.md)
* [../uncategorized/camoproxy.md](../uncategorized/camoproxy.md)
* [../version/version-gitlab-com.md](../version/version-gitlab-com.md)
<!-- END_MARKER -->

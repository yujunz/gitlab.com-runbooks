<!-- MARKER: do not edit this section directly. Edit services/service-mappings.yml then run scripts/generate-docs -->
#  Registry Service

* **Responsible Team**: [package](https://about.gitlab.com/handbook/engineering/dev-backend/)
* **Slack Channel**: [#backend](https://gitlab.slack.com/archives/production/backend)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/WOtyonOiz/general-triage-service?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=registry&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22registry%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com~"Service:Redis"
* **ELK**: [`pubsub-registry-inf-gprd-*`](https://log.gitlab.net/goto/1c2fe46c1db40a7aa7d31875f3fd2ad1)

## Troubleshooting Pointers

* [ci_pending_builds.md](ci_pending_builds.md)
* [ci_too_many_connections_on_runners_cache_server.md](ci_too_many_connections_on_runners_cache_server.md)
* [gitlab-registry.md](gitlab-registry.md)
* [runners-cache.md](runners-cache.md)
* [runners_cache_disk_space.md](runners_cache_disk_space.md)
* [runners_cache_is_down.md](runners_cache_is_down.md)
* [runners_registry_is_down.md](runners_registry_is_down.md)
* [ssl_cert.md](ssl_cert.md)

## Operating Rate

![](https://dashboards.gitlab.com/render/d-solo/WOtyonOiz/general-triage-service?from=now-24h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=registry&orgId=1&panelId=12&width=1200&height=600&tz=UTC&theme=light)

<!-- END_MARKER -->

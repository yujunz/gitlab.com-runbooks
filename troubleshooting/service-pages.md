<!-- MARKER: do not edit this section directly. Edit services/service-mappings.yml then run scripts/generate-docs -->
#  Pages Service

* **Responsible Team**: [release](https://about.gitlab.com/handbook/engineering/dev-backend/)
* **Slack Channel**: [#g_release](https://gitlab.slack.com/archives/g_release)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/WOtyonOiz/general-triage-service?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=pages&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22pages%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Pages"
* **Grafana Folder**: https://dashboards.gitlab.net/dashboards/f/v2ZhpeSik
* **ELK**: [`pubsub-pages-inf-gprd-*`](https://log.gitlab.net/goto/00a732029c1448a741c8730c04038fd9)

## Troubleshooting Pointers

* [chef.md](chef.md)
* [gitaly-unusual-activity.md](gitaly-unusual-activity.md)
* [gitlab-pages.md](gitlab-pages.md)
* [node_memory_alerts.md](node_memory_alerts.md)
<!-- END_MARKER -->

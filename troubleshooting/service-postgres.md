<!-- MARKER: do not edit this section directly. Edit services/service-mappings.yml then run scripts/generate-docs -->
#  Postgres Service

* **Responsible Team**: [infrastructure](https://about.gitlab.com/handbook/engineering/infrastructure/)
* **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/WOtyonOiz/general-triage-service?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=postgres&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22postgres%22%2C%20tier%3D%22db%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Postgres"
* **Grafana Folder**: https://dashboards.gitlab.net/dashboards/f/jYXDze5mk

## Logging

* [Postgres](https://log.gitlab.net/goto/d0f8993486c9007a69d85e3a08f1ea7c)
* [system](https://log.gitlab.net/goto/3669d551a595a3a5cf1e9318b74e6c22)

## Troubleshooting Pointers

* [gitlab-com-is-down.md](gitlab-com-is-down.md)
* [load-balancer-outage.md](load-balancer-outage.md)
* [postgres.md](postgres.md)
<!-- END_MARKER -->

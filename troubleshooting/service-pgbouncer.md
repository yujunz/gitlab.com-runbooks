<!-- MARKER: do not edit this section directly. Edit services/service-mappings.yml then run scripts/generate-docs -->
#  Pgbouncer Service

* **Responsible Team**: [infrastructure](https://about.gitlab.com/handbook/engineering/infrastructure/)
* **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/WOtyonOiz/general-triage-service?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=pgbouncer&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22pgbouncer%22%2C%20tier%3D%22db%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:pgbouncer"
* **Grafana Folder**: https://dashboards.gitlab.net/dashboards/f/jYXDze5mk

## Logging

* [pgbouncer](https://log.gitlab.net/goto/00a732029c1448a741c8730c04038fd9)
* [system](https://log.gitlab.net/goto/ae311f6f133cc1c45b62541977081043)

## Troubleshooting Pointers

* [postgres.md](postgres.md)
<!-- END_MARKER -->

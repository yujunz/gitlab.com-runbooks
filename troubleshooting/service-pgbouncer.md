<!-- MARKER: do not edit this section directly. Edit services/service-mappings.yml then run scripts/generate-docs -->
#  Pgbouncer Service

* **Responsible Team**: [infrastructure](https://about.gitlab.com/handbook/engineering/infrastructure/)
* **Slack Channel**: [#production](https://gitlab.slack.com/archives/production/production)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/WOtyonOiz/general-triage-service?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=pgbouncer&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22pgbouncer%22%2C%20tier%3D%22db%22%7D
* **ELK**: [`pubsub-postgres-inf-gprd-*`](https://log.gitlab.net/goto/365bdf8fb46a83863df50cb618597b79)

## Troubleshooting Pointers

* [postgres.md](postgres.md)
<!-- END_MARKER -->

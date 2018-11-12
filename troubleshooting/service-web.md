<!-- MARKER: do not edit this section directly. Edit services/service-mappings.yml then run scripts/generate-docs -->
#  Web Service

* **Responsible Team**: [backend](https://about.gitlab.com/handbook/engineering/dev-backend/)
* **Slack Channel**: [#backend](https://gitlab.slack.com/archives/backend)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/WOtyonOiz/general-triage-service?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=web&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22web%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Web"
* **Sentry**: https://sentry.gitlab.net/gitlab/gitlabcom/?query=program%3A%22rails%22

## Logging

* [Rails](https://log.gitlab.net/goto/5e1aa9dac377ff2282c70748e9278860)
* [Workhorse](https://log.gitlab.net/goto/cebefc3cf285ce2a94fbfdcadc55f1a4)
* [Unicorn](https://log.gitlab.net/goto/766f73d879983f5ec962d5d6c0ae1cf4)
* [nginx](https://log.gitlab.net/goto/4844ecfa4a7e6f0491685b2cc9224eb0)
* [Unstructured Rails](https://console.cloud.google.com/logs/viewer?project=gitlab-production&interval=PT1H&resource=gce_instance&advancedFilter=jsonPayload.hostname%3A%22web%22%0Alabels.tag%3D%22unstructured.production%22&customFacets=labels.%22compute.googleapis.com%2Fresource_name%22)
* [system](https://log.gitlab.net/goto/c93fb9b8e5df92ed79d993d3a62b5452)

## Troubleshooting Pointers

* [gemnasium_is_down.md](gemnasium_is_down.md)
* [gitaly-latency.md](gitaly-latency.md)
* [postgres.md](postgres.md)
* [recovering-from-nfs-disaster.md](recovering-from-nfs-disaster.md)
* [sentry-is-down.md](sentry-is-down.md)
<!-- END_MARKER -->

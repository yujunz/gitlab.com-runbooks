<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Logging Service

* **Responsible Teams**:
  * [infrastructure-observability](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#observability](https://gitlab.slack.com/archives/observability)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=logging&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22logging%22%2C%20tier%3D%22inf%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Logging"

## Logging

* [Kibana](https://log.gprd.gitlab.net/app/kibana)
* [Stackdriver](https://console.cloud.google.com/logs/viewer?project=gitlab-production)
* [elastic stack monitoring](https://00a4ef3362214c44a044feaa539b4686.us-central1.gcp.cloud.es.io:9243/app/monitoring#/home?_g=(cluster_uuid:RM2uqM76TnWT3JL5n5NzCw))

## Troubleshooting Pointers

* [camoproxy.md](camoproxy.md)
* [gitaly-pubsub.md](gitaly-pubsub.md)
* [gitlab-com-wale-backups.md](gitlab-com-wale-backups.md)
* [gitlab-pages.md](gitlab-pages.md)
* [kubernetes.md](kubernetes.md)
* [pages-letsencrypt.md](pages-letsencrypt.md)
* [pgbouncer.md](pgbouncer.md)
* [postgres.md](postgres.md)
* [pubsub-queing.md](pubsub-queing.md)
* [ssh-maxstartups-breach.md](ssh-maxstartups-breach.md)
* [version-gitlab-com.md](version-gitlab-com.md)
<!-- END_MARKER -->

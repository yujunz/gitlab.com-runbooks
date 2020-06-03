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

* [../elastic/README.md](../elastic/README.md)
* [../elastic/elastic-cloud.md](../elastic/elastic-cloud.md)
* [../elastic/elasticsearch-integration-in-gitlab.md](../elastic/elasticsearch-integration-in-gitlab.md)
* [../elastic/kibana.md](../elastic/kibana.md)
* [../frontend/ssh-maxstartups-breach.md](../frontend/ssh-maxstartups-breach.md)
* [../git/purge-git-data.md](../git/purge-git-data.md)
* [README.md](README.md)
* [logging_gcs_archive_bigquery.md](logging_gcs_archive_bigquery.md)
* [../pages/gitlab-pages.md](../pages/gitlab-pages.md)
* [../pages/pages-letsencrypt.md](../pages/pages-letsencrypt.md)
* [../patroni/geo-patroni-cluster.md](../patroni/geo-patroni-cluster.md)
* [../patroni/gitlab-com-wale-backups.md](../patroni/gitlab-com-wale-backups.md)
* [../patroni/postgres.md](../patroni/postgres.md)
* [../patroni/using-wale-gpg.md](../patroni/using-wale-gpg.md)
* [../pgbouncer/pgbouncer-saturation.md](../pgbouncer/pgbouncer-saturation.md)
* [../pubsub/pubsub-queing.md](../pubsub/pubsub-queing.md)
* [../uncategorized/access-azure-test-subscription.md](../uncategorized/access-azure-test-subscription.md)
* [../uncategorized/access-gcp-hosts.md](../uncategorized/access-gcp-hosts.md)
* [../uncategorized/camoproxy.md](../uncategorized/camoproxy.md)
* [../uncategorized/k8s-gitlab.md](../uncategorized/k8s-gitlab.md)
* [../uncategorized/k8s-operations.md](../uncategorized/k8s-operations.md)
* [../uncategorized/kubernetes.md](../uncategorized/kubernetes.md)
* [../uncategorized/upgrade-docker-machine.md](../uncategorized/upgrade-docker-machine.md)
* [../version/version-gitlab-com.md](../version/version-gitlab-com.md)
* [../web/static-repository-objects-caching.md](../web/static-repository-objects-caching.md)
<!-- END_MARKER -->

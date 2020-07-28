<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Pubsub Service
* [Service Overview](https://dashboards.gitlab.net/d/https://dashboards.gitlab.net/d/USVj3qHmk/logging)
* **Alerts**: https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22pubsub%22%2C%20tier%3D%22inf%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:PubSub"

## Logging

* [stackdriver](https://console.cloud.google.com/logs)
* [multiple indexes in Kibana](https://log.gprd.gitlab.net/goto/2fc394521558a0bfed59f791295ffe51)

## Troubleshooting Pointers

* [../elastic/README.md](../elastic/README.md)
* [../gitaly/find-project-from-hashed-storage.md](../gitaly/find-project-from-hashed-storage.md)
* [../logging/README.md](../logging/README.md)
* [../patroni/postgresql-backups-wale-walg.md](../patroni/postgresql-backups-wale-walg.md)
* [../praefect/praefect-error-rate.md](../praefect/praefect-error-rate.md)
* [pubsub-queing.md](pubsub-queing.md)
* [../registry/gitlab-registry.md](../registry/gitlab-registry.md)
* [../sidekiq/sidekiq-survival-guide-for-sres.md](../sidekiq/sidekiq-survival-guide-for-sres.md)
* [../uncategorized/camoproxy.md](../uncategorized/camoproxy.md)
* [../uncategorized/k8s-gitlab.md](../uncategorized/k8s-gitlab.md)
<!-- END_MARKER -->

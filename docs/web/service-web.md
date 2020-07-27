<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Web Service
* [Service Overview](https://dashboards.gitlab.net/d/web-main/web-overview?)
* **Alerts**: https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22web%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Web"

## Logging

* [Rails](https://log.gprd.gitlab.net/goto/5e1aa9dac377ff2282c70748e9278860)
* [Workhorse](https://log.gprd.gitlab.net/goto/cebefc3cf285ce2a94fbfdcadc55f1a4)
* [Unicorn](https://log.gprd.gitlab.net/goto/766f73d879983f5ec962d5d6c0ae1cf4)
* [nginx](https://log.gprd.gitlab.net/goto/4844ecfa4a7e6f0491685b2cc9224eb0)
* [Unstructured Rails](https://console.cloud.google.com/logs/viewer?project=gitlab-production&interval=PT1H&resource=gce_instance&advancedFilter=jsonPayload.hostname%3A%22web%22%0Alabels.tag%3D%22unstructured.production%22&customFacets=labels.%22compute.googleapis.com%2Fresource_name%22)
* [system](https://log.gprd.gitlab.net/goto/c93fb9b8e5df92ed79d993d3a62b5452)

## Troubleshooting Pointers

* [../cloudflare/README.md](../cloudflare/README.md)
* [../cloudflare/managing-traffic.md](../cloudflare/managing-traffic.md)
* [../cloudflare/services-locations.md](../cloudflare/services-locations.md)
* [../cloudflare/troubleshooting.md](../cloudflare/troubleshooting.md)
* [../elastic/elastic-cloud.md](../elastic/elastic-cloud.md)
* [../elastic/kibana.md](../elastic/kibana.md)
* [../forum/discourse-forum.md](../forum/discourse-forum.md)
* [../frontend/haproxy.md](../frontend/haproxy.md)
* [../git/deploy-gitlab-rb-change.md](../git/deploy-gitlab-rb-change.md)
* [../git/gitlab-hosted-codesandbox.md](../git/gitlab-hosted-codesandbox.md)
* [../gitaly/gitaly-down.md](../gitaly/gitaly-down.md)
* [../gitaly/gitaly-latency.md](../gitaly/gitaly-latency.md)
* [../gitaly/gitaly-profiling.md](../gitaly/gitaly-profiling.md)
* [../gitaly/gitaly-token-rotation.md](../gitaly/gitaly-token-rotation.md)
* [../gitaly/gitaly-unusual-activity.md](../gitaly/gitaly-unusual-activity.md)
* [../gitaly/storage-servers.md](../gitaly/storage-servers.md)
* [../monitoring/sentry-is-down.md](../monitoring/sentry-is-down.md)
* [../nfs/recovering-from-nfs-disaster.md](../nfs/recovering-from-nfs-disaster.md)
* [../patroni/postgres.md](../patroni/postgres.md)
* [../patroni/postgresql-backups-wale-walg.md](../patroni/postgresql-backups-wale-walg.md)
* [../pgbouncer/README.md](../pgbouncer/README.md)
* [../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md](../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md)
* [../pgbouncer/pgbouncer-connections.md](../pgbouncer/pgbouncer-connections.md)
* [../pgbouncer/pgbouncer-saturation.md](../pgbouncer/pgbouncer-saturation.md)
* [../sidekiq/sidekiq-survival-guide-for-sres.md](../sidekiq/sidekiq-survival-guide-for-sres.md)
* [../uncategorized/blocked-user-logins.md](../uncategorized/blocked-user-logins.md)
* [../uncategorized/chef-documentation.md](../uncategorized/chef-documentation.md)
* [../uncategorized/chef-guidelines.md](../uncategorized/chef-guidelines.md)
* [../uncategorized/debug-failed-chef-provisioning.md](../uncategorized/debug-failed-chef-provisioning.md)
* [../uncategorized/deploycmd.md](../uncategorized/deploycmd.md)
* [../uncategorized/domain-registration.md](../uncategorized/domain-registration.md)
* [../uncategorized/gemnasium_is_down.md](../uncategorized/gemnasium_is_down.md)
* [../uncategorized/manage-workers.md](../uncategorized/manage-workers.md)
* [../uncategorized/project-export.md](../uncategorized/project-export.md)
* [../uncategorized/setup-oauth2-proxy-protected-application.md](../uncategorized/setup-oauth2-proxy-protected-application.md)
<!-- END_MARKER -->

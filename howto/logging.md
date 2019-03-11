# Application logging at gitlab

**IMPORTANT** : Previously production logs were using the `pubsub-production-*` indices, this has change to the `pubsub-rails-*` indices. For more info see the [table](logging.md#what-are-we-logging).

## Summary

**https://log.gitlab.net**

### Quick Start

_For information about index names and how they map to log files see the
[table](logging.md#what-are-we-logging) below._

#### Production

To find production logs select the corresponding indexes with `pubsub-*-gprd` in the name

* For azure filter by `json.environment: prd`
* For GCP filter by `json.environment: gprd`

#### Staging

To find production logs select the corresponding indexes with `pubsub-*-gstg` in the name

* For Azure filter by `json.environment: stg`
* For GCP filter by `json.environment: gstg`


#### .org (dev.gitlab.org)

To find .org logs select the corresponding indexes with `pubsub-*-gstg` in the name

* For azure filter by `json.environment: dev`
* For GCP filter by `json.environment: dev`

#### Runners

To find logs for runners select the `pubsub-syslog-gprd` index.

* For both azure and GCP filter by `json.environment: ci-prd` or `json.environment: ci-stg`.

_Note: Runner logs are unstructured and mixed in with other syslog messages, structured logging tracked with https://gitlab.com/gitlab-org/gitlab-runner/issues/3336_


### StackDriver

All logs listed in the [table](logging.md#what-are-we-logging) below are processed by StackDriver, but
most are excluded from it's indexing for cost reasons. It is sometimes helpful to use
it to search for logs over a 30day interval for the included logs. It also allows
you to do basic queries for strings across all types and find errors.

The current exclusions for StackDriver can be found in [terraform variables.tf](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/blob/master/shared/gstg-gprd/variables.tf),
search for `sd_log_filters`.

### BigQuery

The `haproxy` logs are also configured to be forwarded to a BigQuery dataset using
a StackDriver sink: [gitlab-production:haproxy_logs](https://console.cloud.google.com/bigquery?organizationId=769164969568&project=gitlab-production&p=gitlab-production&d=haproxy_logs&page=dataset)


## Overview

Centralized logging at GitLab uses a combination of StackDriver, FluentD, google pubsub,
and ElasticSearch / Kibana. All logs for the production, staging, gprd and
gstg environments are forwarded to log.gitlab.net.

![Logical scheme](../img/logging-infr.png)

### Stackdriver exporter

There is a VM in each environment called `sd-exporter-*`. This VM is created using a generic terraform module https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/google/generic-sv-with-group . The VM has a chef role assigned to it which downloads and runs the stackdriver exporter https://gitlab.com/gitlab-cookbooks/gitlab-exporters/ . The exporter service runs on a tcp port number 9255. Prometheus is configured through a role in chef-repo to scrape port 9255 on "sd-exporter-*" VM.

### What are we logging?

**production.log and haproxy logs are no longer being sent to elasticcloud due because it was overwhelming our cluster, currently these logs are only available in StackDriver**

**All logs not excluded from from StackDriver are stored in stackdriver for 30 days**

**All logs processed by StackDriver are archived object storage for a minimum of 180days even if excluded**

For retention in elasticcloud, see the cleanup script - https://gitlab.com/gitlab-restore/esc-tools/blob/master/cleanup_indices.sh

| name | logfile  | type  | index | stackdriver filter |
| -----| -------- |------ | ----- |--------------------|
| gitaly | gitaly/current | JSON | pubsub-gitaly-inf | |
| pages | gitlab-pages/current | JSON | pubsub-pages-inf | |
| db.postgres | postgresql/current | line regex | pubsub-postgres-inf | |
| db.pgbouncer | gitlab/pgbouncer/current | line regex | pubsub-postgres-inf | |
| workhorse | gitlab/gitlab-workhorse/current | JSON | pubsub-workhorse-inf | |
| rails.api | gitlab-rails/api\_json.log | JSON | pubsub-rails-inf | |
| rails.application | gitlab-rails/application.log | JSON | pubsub-application-inf | |
| rails.audit | gitlab-rails/audit_json.log | JSON | pubsub-rails-inf | |
| rails.kubernetes | gitlab-rails/kubernetes.log | JSON | pubsub-rails-inf | |
| rails.geo | gitlab-rails/geo.log | JSON | pubsub-rails-inf | |
| rails.importer | gitlab-rails/impoter.log | JSON | pubsub-rails-inf | |
| rails.integrations | gitlab-rails/integrations\_json.log | JSON | pubsub-rails-inf | |
| rails.production | gitlab-rails/production\_json.log | JSON | pubsub-rails-inf | |
| shell | gitlab-shell/gitlab-shell.log | JSON | pubsub-shell-inf | |
| unicorn.current | /var/log/gitlab/unicorn/current | line regex | pubsub-unicorn-inf | |
| unicorn.stderr | /var/log/gitlab/unicorn/unicorn\_stderr.log | line regex | pubsub-unicorn-inf | |
| unicorn.stdout | /var/log/gitlab/unicorn/unicorn\_stdout.log | line regex | pubsub-unicorn-inf | |
| unstructured.production | gitlab-rails/production.log | lines | pubsub-unstructured-inf | label.tag="unstrucctured.production" |
| sidekiq | /var/log/gitlab/sidekiq-cluster/current |  JSON | pubsub-sidekiq-inf | |
| haproxy | /var/log/haproxy.log | syslog | pubsub-haproxy-inf | label.tag="haproxy" |
| nginx.access | /var/log/gitlab/nginx/gitlab\_access.log | nginx | pubsub-nginx-inf | |
| registry | /var/log/gitlab/registry/current | lines | pubsub-registry-inf | |
| system.auth | /var/log/auth.log | syslog | pubsub-system-inf | |
| system.syslog | /var/log/syslog | syslog | pubsub-system-inf | |
| history.psql | /home/*-db/.psql_history  | | |
| history.irb | /var/log/irb_history/*.log  | | |


### FAQ

#### Why are we using StackDriver in addition to ElasticSearch?

We are sending logs to stackdriver in addition to elasticsearch for
longer retention and to preserve logs in object storage for 180days.

#### How do I find the right logs for my service?

* Navigate to https://log.gitlab.net
* Select the appropriate index (see chart above).
  * Azure production and GCP production logs are in the *gprd* `*-gprd*` indexes
  * Azure staging and GCP staging logs are in the *gstg* `*-gstg*` indexes
* Optionally filter by environment if you only want to see logs for azure or gcp.
  * `+json.environment: prd` for Azure production
  * `+json.environment: gprd` for Google production

#### A user sees an error on GitLab com, how do I find logs for that user?

* Select the `pubsub-production-inf-grpd*` index
* Search for `+json.username: <user>`

#### Why do we have these annoying json. prefixes?

They are created by https://github.com/GoogleCloudPlatform/pubsubbeat , I don't see a way we can remove them without forking the project.

#### What if I need to query logs older than 30 days?

See [logging_gcs_archive_bigquery.md](logging_gcs_archive_bigquery.md) for
instructions on loading logs into `BigQuery` from their GCS archive files.

### Configuration

#### Cookbooks

There are three cookbooks that configure logging on gitlab.com

* gitlab-proxy - Sets up the nginx proxy so that users can access elastic cloud via log.gitlab.net
* gitlab_fluentd - Sets up td-agent on all nodes, forwards logs to pubsub topics.
* gitlab-elk - Sets up the pubsub beat which reads from the topics and forwards to elastic cloud.

#### Role configuration

* There is a [single role for all pubsub beats](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/roles/gprd-infra-pubsub.json) per environment, the index is determined by the hostname which allows it to be dyamic.
* Add `recipe[gitlab_fluentd::<type>]` to the corresponding role to enable td-agent for the template
* The [ops proxy role](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/roles/ops-infra-proxy.json) configures the proxy vm that is the reverse proxy for elastic cloud.


#### Terraform

Pub/Sub Topics are managed by terraform (specifically,
[the pubsubbeat module](https://gitlab.com/gitlab-com/gl-infra/terraform-modules/google/pubsubbeat)).

Pub/Sub Subscriptions should be automatically created by the pubsubbeat service
on each pubsub host. If subscriptions get misconfigured (e.g. topics appear
as `_deleted-topic_`) you can delete them and restart the pubsubbeat services to
re-create them.

#### Adding a new logfile

* Decide whether you want a new pubsub topic (which means a new index) or use an existing one
* If you want to use an existing index simply update one of [fluentd templates](https://gitlab.com/gitlab-cookbooks/gitlab_fluentd/tree/master/templates/default) and add a section for the new log.
* If youw ant to create a new index, first modify the `variables.tf` of the `gprd` and `gstg` environment so that there is a new topic and a new pubsubbeat to monitor it.
* Add a new "name" and "machine type", see this example:

```
variable "pubsubbeats" {
  type = "map"

  default = {
    "names"         = ["gitaly", "haproxy", "pages", "postgres", "production", "system", "workhorse", "geo", "sidekiq", "api"]
    "machine_types" = ["n1-standard-8", "n1-standard-8", "n1-standard-4", "n1-standard-4", "n1-standard-8", "n1-standard-8", "n1-standard-8", "n1-standard-4", "n1-standard-8", "n1-standard-4"]
  }
}
```

* Note: try to use a small instance type and increase it if necessary.
* Run terraform
* If you are using a new index you will need to add a [new template to fluentd](https://gitlab.com/gitlab-cookbooks/gitlab_fluentd/tree/master/templates/default).
* After the template is created, add the recipe to the nodes that have the logfile.

### Monitoring and Troubleshooting

* To ensure that pubsub messages are being consumed and sent to elasticsearch see the [stackdriver pubsub dashboards](https://app.google.stackdriver.com/monitoring/1088234/logging-pubsub-in-gprd?project=gitlab-production)
* Monitoring of td-agent (TBD) https://gitlab.com/gitlab-com/migration/issues/390
* Monitoring of pubsub (TBD) https://gitlab.com/gitlab-com/migration/issues/389

#### Logs have stopped showing up on elastic search

* Find the appropriate beat for the index, look for the vm that matches the index name
* SSH to the vm and look at the `/var/log/pubsubbeat/current` logfile to see if there are any errors.
* If there are no errors check out the `/var/log/tg-agent` logfile on one of the nodes sending logs.

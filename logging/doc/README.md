<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Quick start](#quick-start)
    - [URLs](#urls)
    - [Retention](#retention)
    - [What are we logging?](#what-are-we-logging)
    - [Historical notes](#historical-notes)
- [How-to guides](#how-to-guides)
    - [Searching logs](#searching-logs)
        - [Searching in Elastic](#searching-in-elastic)
            - [production (gitlab.com)](#production-gitlabcom)
            - [dev (dev.gitlab.org), staging (staging.gitlab.com), dr, ops (ops.gitlab.com), preprod (pre.gitlab.com)](#dev-devgitlaborg-staging-staginggitlabcom-dr-ops-opsgitlabcom-preprod-pregitlabcom)
        - [Searching in StackDriver](#searching-in-stackdriver)
        - [Searching in object storage (GCS)](#searching-in-object-storage-gcs)
- [Concepts](#concepts)
    - [Logging infrastructure overview](#logging-infrastructure-overview)
    - [Fluentd](#fluentd)
    - [StackDriver](#stackdriver)
    - [Cloud Pub/Sub](#cloud-pubsub)
    - [Pubsubbeat VMs](#pubsubbeat-vms)
    - [Elastic](#elastic)
    - [Index Lifecycle Management (ILM)](#index-lifecycle-management-ilm)
    - [Monitoring](#monitoring)
    - [BigQuery](#bigquery)
    - [GCS (long-term storage)](#gcs-long-term-storage)
- [FAQ](#faq)
    - [Why are we using StackDriver and GCS in addition to ElasticSearch?](#why-are-we-using-stackdriver-and-gcs-in-addition-to-elasticsearch)
    - [Why are we using pubsub queues instead of sending logs from fluentd directly to Elastic?](#why-are-we-using-pubsub-queues-instead-of-sending-logs-from-fluentd-directly-to-elastic)
    - [How do I find the right logs for my service?](#how-do-i-find-the-right-logs-for-my-service)
    - [A user sees an error on GitLab.com, how do I find logs for that user?](#a-user-sees-an-error-on-gitlabcom-how-do-i-find-logs-for-that-user)
    - [Why do we have these annoying json. prefixes?](#why-do-we-have-these-annoying-json-prefixes)
    - [What if I need to query logs older than the ones present in Elastic?](#what-if-i-need-to-query-logs-older-than-the-ones-present-in-elastic)
    - [What if I need to query logs older than 30 days?](#what-if-i-need-to-query-logs-older-than-30-days)
- [Configuration](#configuration)
    - [Cookbooks](#cookbooks)
    - [logs parsers](#logs-parsers)
        - [Elastic mappings](#elastic-mappings)
    - [Role configuration](#role-configuration)
    - [Terraform](#terraform)
    - [Adding a new logfile](#adding-a-new-logfile)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


# Quick start #

## URLs ##

Logging clusters:
- **https://log.gprd.gitlab.net**
- **https://nonprod-log.gitlab.net**

StackDriver:
- **https://console.cloud.google.com/logs?organizationId=769164969568&project=gitlab-staging-1** (select "GCE VM instance" from the dropdown menu of resources -> select "All instance_id" -> select "All logs"/logs from a component you're interested in from the dropdown menu of log sources)

BigQuery:
- **[BigQuery](./logging_gcs_archive_bigquery.md)**

## Retention

See [ESC-tools clean up script](https://ops.gitlab.net/gitlab-com/gl-infra/gitlab-restore/esc-tools/blob/master/cleanup_indices.sh) for up to date retention time.

| Index                        | Production (gprd) | Staging (gstg) |
|------------------------------|------------|---------|
| pubsub-application-inf       | 10 days    | 1 day   |
| pubsub-gitaly-inf            | 7 days     | 1 day   |
| pubsub-haproxy-inf           | 2 days     | 1 day   |
| pubsub-pages-inf             | 10 days    | 1 day   |
| pubsub-postgres-inf          | 6 days     | 1 day   |
| pubsub-rails-inf             | 7 days     | 1 day   |
| pubsub-shell-inf             | 7 days     | 1 day   |
| pubsub-sidekiq-inf           | 7 days     | 1 day   |
| pubsub-system-inf            | 3 days     | 1 day   |
| pubsub-unicorn-inf           | 10 days    | 1 day   |
| pubsub-unstructured-inf      | 3 days     | 1 day   |
| pubsub-workhorse-inf         | 3 days     | 1 day   |
| pubsub-consul-inf            | 6 days     | 1 day   |
| default for everything else  | 1 day      | 1 day   |

Logs indexed by Stackdriver are stored for 30 days

All logs processed by StackDriver (even if excluded from indexing) are archived to object storage (GCS). Retention in GCS is currently configured for 365 days. For more details see [gcs section below](#gcs-long-term-storage).

## What are we logging? ##


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
| rails.auth | gitlab-rails/auth.log | JSON | pubsub-rails-inf | |
| rails.database_load_balancing | gitlab-rails/database_load_balancing.log | JSON | pubsub-rails-inf | |
| rails.geo | gitlab-rails/geo.log | JSON | pubsub-rails-inf | |
| rails.git | gitlab-rails/git_json.log | JSON | pubsub-rails-inf | |
| rails.importer | gitlab-rails/importer.log | JSON | pubsub-rails-inf | |
| rails.integrations | gitlab-rails/integrations\_json.log | JSON | pubsub-rails-inf | |
| rails.kubernetes | gitlab-rails/kubernetes.log | JSON | pubsub-rails-inf | |
| rails.exceptions | /var/log/gitlab/gitlab-rails/exceptions_json.log | JSON | pubsub-rails-inf | |
| rails.production | gitlab-rails/production\_json.log | JSON | pubsub-rails-inf | |
| shell | gitlab-shell/gitlab-shell.log | JSON | pubsub-shell-inf | |
| unicorn.current | /var/log/gitlab/unicorn/current | line regex | pubsub-unicorn-inf | |
| unicorn.stderr | /var/log/gitlab/unicorn/unicorn\_stderr.log | line regex | pubsub-unicorn-inf | |
| unicorn.stdout | /var/log/gitlab/unicorn/unicorn\_stdout.log | line regex | pubsub-unicorn-inf | |
| unstructured.production | gitlab-rails/production.log | lines | pubsub-unstructured-inf | label.tag="unstrucctured.production" |
| sidekiq | /var/log/gitlab/sidekiq-cluster/current |  JSON | pubsub-sidekiq-inf | |
| haproxy | /var/log/haproxy.log | syslog | pubsub-haproxy-inf | label.tag="haproxy" |
| nginx.access | /var/log/gitlab/nginx/gitlab\_access.log | nginx | pubsub-nginx-inf | |
| registry | n/a | mix (lines/json) | pubsub-gke-inf | |
| system.auth | /var/log/auth.log | syslog | pubsub-system-inf | |
| system.syslog | /var/log/syslog | syslog | pubsub-system-inf | |
| rails.graphql | /var/log/gitlab/gitlab-rails/graphql_json.log | JSON | pubsub-rails-inf ||
| rails.mail_room | /var/log/gitlab/mailroom/mail_room_json.log | JSON | pubsub-rails-inf ||
| history.psql | /home/*-db/.psql_history  | | |
| history.irb | /var/log/irb_history/*.log  | | |


## Historical notes ##

Logs from all environments used to be available at https://log.gitlab.net/ .

Previously production logs were using the `pubsub-production-*` pattern, this has changed to `pubsub-rails-inf-gprd-*`. For more info see the [table](#what-are-we-logging).

production.log, haproxy logs and nginx logs are no longer being sent to elasticcloud because it was overwhelming our cluster, currently these logs are only available in StackDriver.

Runner logs used to be unstructured and mixed in with other syslog messages, structured logging was tracked with https://gitlab.com/gitlab-org/gitlab-runner/issues/3336 . Runner logs now have a dedicated index.

Design document for migration to ES7: https://about.gitlab.com/handbook/engineering/infrastructure/design/logging-upgrade/

# How-to guides

## Searching logs

### Searching in Elastic

#### production (gitlab.com) ####

1. Go to https://log.gprd.gitlab.net/
1. in Kibana, in Discover application, select the relevant index pattern, e.g. `pubsub-rails-inf-gprd-*`

#### dev (dev.gitlab.org), staging (staging.gitlab.com), dr, ops (ops.gitlab.com), preprod (pre.gitlab.com) ####

1. Go to https://nonprod-log.gitlab.net/
1. select the relevant index pattern, e.g. `pubsub-rails-inf-gstg-*` or `pubsub-rails-inf-ops-*`
1. (optional) filter on the environment, e.g. `json.environment=gstg` or `json.environment=dev`

Note:
- logs from dev are sent to staging indices
- almost no logs are forwarded from preprod

### Searching in StackDriver ###

### Searching in object storage (GCS) ###

[using BigQuery tutorial](./logging_gcs_archive_bigquery.md)

# Concepts #

## Logging infrastructure overview ##

![Overview](./img/logging.png)

## Fluentd

Files containing logs are parsed by Fluentd (td-agent). Fluentd runs directly on a number of different VMs across our fleet or as a [daemonset](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/) inside kubernetes. Fluentd running on VMs is configured to send logs to two destinations: [Stackdriver](https://cloud.google.com/stackdriver/docs/) and [Cloud Pub/Sub](https://cloud.google.com/pubsub/docs/). Fluentd running as a daemonset, sends logs only to Stackdriver.

## StackDriver ##

All logs reaching Stackdriver are saved to GCS using an export sink where they are stored long-term (e.g. 6 months) for compliance reasons and can be read using BigQuery. Kubernetes logs are also forwarded from Stackdriver to Pub/Sub (that's because Fluentd in kubernetes is not forwarding logs to Pub/Sub).

All logs listed in the [table](#what-are-we-logging) are processed by StackDriver, but most are excluded from indexing due to costs. It is sometimes helpful to use it to search for logs over a 30 day interval for the included logs. It also allows you to do basic queries for strings across all types and find errors.

The current exclusions for StackDriver can be found in [terraform variables.tf](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/blob/master/environments/gprd/variables.tf),
search for `sd_log_filters`.

Logs sent to StackDriver are sent to "GCE VM instance" resource logs.

## Cloud Pub/Sub

Logs from different components have designated topics in Pub/Sub and each topic has a corresponding subscription. There is a subscriber for each subscription. At the moment of writing we are using pubsubbeat to subscribe to Pub/Sub subscriptions and forward logs to an Elastic cluster.

Examples of alternatives to Cloud Pub/Sub include: Kafka

## Pubsubbeat VMs

Pubsubbeat runs on dedicated VMs. The binary pulls logs from a subscription in Pub/Sub and uploads them to Elastic using the [bulk API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html). The default configuration of Pubsubbeat is to create templates and field mappings in indices. However, we are instead relying on the dynamic mappings created by the Elastic cluster.

Examples of alternatives to Pubsubbeat include: Filebeat, Fluentd, Logstash.

## Elastic

Aliases are referenced by Pubsubbeat when uploading logs to Elastic. When logs reach the Elastic cluster, they are indexed into documents by a worker, the alias name is resolved to an index name and the documents are saved in the index. There should only ever be one active index per alias and the alias should be pointing to that index.

Logs (documents) can be viewed in Kibana using index patterns, i.e. when you open the Discover application in Kibana, you can select the index pattern from a drop-down list and all searches you will submit will be performed against all indices matching the index pattern. There are also a number of other features in Kibana we're using: dashboards, saved searches, visualizations, watchers.

More documentation on Elastic can be found here: [elastic/doc/](./elastic/doc/)

## Index Lifecycle Management (ILM)

Indices can be managed in different ways e.g. custom scripts, Curator, Index Lifecycle Management (ILM) plugin. ILM meets a lot of our requirements so that's what we're using for logs sent to ES7 clusters.

[The ILM plugin](https://www.elastic.co/guide/en/elasticsearch/reference/current/getting-started-index-lifecycle-management.html) has proved to be particularly useful and has become very popular in the Elastic community in recent years. For this reason, it was integrated into Elastic.

ILM behavior is configured via policies assigned to indices. The plugin runs at a scheduled interval (like a cronjob). When triggered, ILM goes through each index that has a policy assigned to it and performs a step defined in the policy (assigned to that particular index). If the conditions are not met, ILM will do nothing. Notice that the conditions are evaluated on a scheduled basis (rather than being event driven).

Policies can define a number of steps which in simple words translate to: warm -> hot -> cold -> delete. Behavior of ILM at each of those steps is defined in the ILM policy.

Here's an example policy:
```
{
    "policy": {
        "phases": {
            "hot": {
                "actions": {
                    "rollover": {
                        "max_age": "3d",
                        "max_size": "50gb"
                    },
                    "set_priority": {
                        "priority": 100
                    }
                }
            },
            "warm": {
                "min_age": "1m",
                "actions": {
                    "forcemerge": {
                        "max_num_segments": 1
                    },
                    "allocate": {
                        "require": {
                            "data": "warm"
                        }
					          },
					          "set_priority": {
						            "priority": 50
                    }
                }
            },
            "delete": {
                "min_age": "7d",
                "actions": {
                    "delete": {}
                }
            }
        }
    }
}
```
Let's say ILM is configured to run every 10 mins and the above policy is assigned to a newly created index. What will happen, is after 10 mins, ILM will trigger the hot phase, which will check the size and age of the index. If the size exceeds 50GB or the age exceeds 3 days, the configured [action](https://www.elastic.co/guide/en/elasticsearch/reference/current/_actions.html) is triggered, which in this case would send a call to the [rollover api](https://www.elastic.co/guide/en/elasticsearch/reference/master/indices-rollover-index.html). The rollover API will mark the current index as non-writable, mark it for the warm phase and create a new index from an index template. This way, we can control for example the size of shards within indices or logs retention period.

See also:
- https://www.elastic.co/blog/implementing-hot-warm-cold-in-elasticsearch-with-index-lifecycle-management
- https://www.elastic.co/guide/en/elasticsearch/reference/current/index-lifecycle-management.html

## Monitoring

For monitoring Elastic clusters see: [elastic/doc/README.md#monitoring](./elastic/doc/README.md#monitoring)
Our Elastic clusters have monitoring enabled and the monitoring metrics are forwarded to a separate monitoring cluster.

There is a VM in each environment called `sd-exporter-*`. This VM is created using a generic terraform module https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/google/generic-sv-with-group . The VM has a chef role assigned to it which downloads and runs the stackdriver exporter https://gitlab.com/gitlab-cookbooks/gitlab-exporters/ . The exporter service runs on a tcp port number 9255. Prometheus is configured through a role in chef-repo to scrape port 9255 on `sd-exporter-*` VMs. Metrics scraped this way are the basis for Prometheus pubsub alerts.

## BigQuery ##

BigQuery can be used to search logs that are in cold storage (GCS).

The `haproxy` logs are also configured to be forwarded to a BigQuery dataset using
a StackDriver sink: [gitlab-production:haproxy_logs](https://console.cloud.google.com/bigquery?organizationId=769164969568&project=gitlab-production&p=gitlab-production&d=haproxy_logs&page=dataset)

## GCS (long-term storage) ##

Logs from the export sink are saved to a GCS bucket which we manage with Terraform: https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/google/storage-buckets/blob/master/main.tf#L1

We configure this bucket with GCP lifecycle rules: https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/google/storage-buckets/blob/master/main.tf#L14

These rules are parameterized and are configured with defaults which are set in the module: https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/google/storage-buckets/blob/master/variables.tf#L150

# FAQ #

## Why are we using StackDriver and GCS in addition to ElasticSearch? ##

We are sending logs to Stackdriver and GCS in addition to elasticsearch for
longer retention and to preserve logs in object storage for 365 days.

## Why are we using pubsub queues instead of sending logs from fluentd directly to Elastic? ##

We use it for two reasons. Firstly, to handle situations when our log sources emit more logs than Elasticsearch can ingest at real time. In this scenario, pubsub serves the role of a buffer.

Secondly, we were overloading Elastic Cloud with the number of connections. Having only a few pubsubbeats helps to reduce the overhead of a separate connection for each fluentd instance.

## How do I find the right logs for my service? ##

See [Quick start](./README.md#what-are-we-logging)

## A user sees an error on GitLab.com, how do I find logs for that user? ##

* Select the `pubsub-rails-inf-gprd-*` index pattern in Kibana
* Search for `+json.username: <user>`

If the request has `json.correlation_id` field set, you can use that id for checking logs from all gitlab.com components using the Correlation dashboard.

see also: [searching logs](./README.md#searching-logs)

## Why do we have these annoying json. prefixes? ##

They are created by https://github.com/GoogleCloudPlatform/pubsubbeat , I don't see a way we can remove them without forking the project.

## What if I need to query logs older than the ones present in Elastic? ##

StackDriver can be used for searching logs from the last 30 days and BigQuery for older ones, stored in GCS.

## What if I need to query logs older than 30 days? ##

See [logging_gcs_archive_bigquery.md](logging_gcs_archive_bigquery.md) for
instructions on loading logs into `BigQuery` from their GCS archive files.

# Configuration #

## Cookbooks ##

There are three cookbooks that configure logging on gitlab.com

* gitlab-proxy - Sets up the nginx proxy so that users can access elastic cloud via log.gitlab.net
* gitlab_fluentd - Sets up td-agent on all nodes, forwards logs to pubsub topics.
* gitlab-elk - Sets up the pubsub beat which reads from the topics and forwards to elastic cloud.

## logs parsers ##

### Elastic mappings ###

We are utilizing dynamic mappings in Elastic for majority of field mappings. In selected few cases where the mappings need to be adjusted we use mappings added to index templates.

In the past, we used static mappings in logsearch and dynamic mappings generated by pubsubbeat.

## Role configuration ##

* There is a [single role for all pubsub beats](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/roles/gprd-infra-pubsub.json) per environment, the index is determined by the hostname which allows it to be dyamic.
* Add `recipe[gitlab_fluentd::<type>]` to the corresponding role to enable td-agent for the template
* The [ops proxy role](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/roles/ops-infra-proxy.json) configures the proxy vm that is the reverse proxy for elastic cloud.


## Terraform ##

Pub/Sub Topics are managed by terraform (specifically,
[the pubsubbeat module](https://gitlab.com/gitlab-com/gl-infra/terraform-modules/google/pubsubbeat)).

Pub/Sub Subscriptions should be automatically created by the pubsubbeat service
on each pubsub host. If subscriptions get misconfigured (e.g. topics appear
as `_deleted-topic_`) you can delete them and restart the pubsubbeat services to
re-create them.

## Adding a new logfile ##

* Decide whether you want to use an existing ES index or create a new one (which will also require making some changes using Terraform). Some hints about how to decide:
    * You won't need a dedicated index if the amount of logs is small (at the moment of writing, the overhead related to operating a separate index is quite significant)
    * It makes sense to use an existing index if the log file "conceptually" belongs to an existing log stream (for example it used be part of rails logs and it's simply going to be separated into a dedicate file)

* Adding a logfile and using an existing ES index
    * Update one of the [fluentd templates](https://gitlab.com/gitlab-cookbooks/gitlab_fluentd/tree/master/templates/default) and add a section for the new log file. Remember to bump the cookbook version in `metadata.rb`
    * follow the chef roll out process
* Adding a logfile and creating a dedicated index for it
    * Add your index to the list of objects managed in the git repo, for example: https://gitlab.com/gitlab-com/runbooks/merge_requests/1736 . This will ensure that any changes to config will be applied to your new index and that in case of a disaster recovery the index will be recreated.
    * Seed Elastic:
        * Get credetials for the relevant ES cluster from 1password and source them in bash. You can find the name of the env var that you should use in the script that you'll run in the next step.
        * Run the script updating index templates, for example for the nonprod cluster: https://gitlab.com/gitlab-com/runbooks/blob/master/elastic/managed-objects/nonprod-log/index-templates/update-index-templates.sh
        * Initialize the alias and create the first index using an api call documented here: https://gitlab.com/gitlab-com/runbooks/blob/master/elastic/api_calls/single/initialize-alias-create-index.sh
        * Make sure that all three exist in the relevant cluster: alias, index template, first index and that the index has an ILM policy assigned to it.
        * Create a json file with an index-pattern similar to this one: https://gitlab.com/gitlab-com/runbooks/tree/master/elastic/managed-objects/nonprod-log/index-patterns/pubsub-api-inf-dr.json and using the json file create the index pattern in Kibana using a POST request
        * The ES cluster is now ready to start receiving new logs.
    * Terraform changes
        * Modify the `variables.tf` file of the environment where you want to make the change, e.g. https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/merge_requests/1249/diffs . This will create a dedicated pubsub topic and a pubsubbeat VM. The VM will be configured with the relevant Chef role which will start a pubsubbeat process. The pubsubbeat process will be configured with the topic name and will automatically create a subscription to the topic. It is also configured not to create templates and indices (we do that over the api so that we have control over things like mappings and index settings).
        * Follow our usual process for applying Terraform changes
    * Chef changes
        * Add a new recipe in the `gitlab_fluentd` cookbook for your log file, for example: https://gitlab.com/gitlab-cookbooks/gitlab_fluentd/merge_requests/99/diffs
        * Edit the relevant roles in the chef repo to apply the new recipe to VMs managed with that role, for example: https://ops.gitlab.net/gitlab-cookbooks/chef-repo/merge_requests/2367/diffs
        * follow the chef roll out process

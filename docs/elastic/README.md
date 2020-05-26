<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Quick start](#quick-start)
    - [Elastic related resources](#elastic-related-resources)
    - [Historical notes](#historical-notes)
- [How-to guides](#how-to-guides)
    - [Performing operations on the Elastic cluster](#performing-operations-on-the-elastic-cluster)
    - [Estimating Log Volume and Cluster Size](#estimating-log-volume-and-cluster-size)
        - [What is going to Stackdriver?](#what-is-going-to-stackdriver)
        - [What is the Volume of our PubSub topics?](#what-is-the-volume-of-our-pubsub-topics)
        - [How much elastic storage are we using per day?](#how-much-elastic-storage-are-we-using-per-day)
- [Concepts](#concepts)
    - [Elastic learning materials](#elastic-learning-materials)
    - [Design Document (Elastic at Gitlab)](#design-document-elastic-at-gitlab)
    - [Monitoring](#monitoring)
    - [Alerting](#alerting)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Quick start

## Elastic related resources ##

1. [Logging dashboard in Grafana](https://dashboards.gitlab.net/d/USVj3qHmk/logging?orgId=1&from=now-7d&to=now)
1. runbooks repo:
    1. documentation
    1. Prometheus alerts
    1. dashboards/watchers/visualizations/searches
1. terraform config:
    1. infra managed in the `gitlab-com-infrastructure` repo (e.g. pubsubbeat VMs, stackdriver exporter)
    1. relevant terraform modules
1. chef config
1. Design documents in `www-gitlab-com` repo:
TODO: link here design docs once they are ready
1. Logging working group: https://about.gitlab.com/company/team/structure/working-groups/log-aggregation/
1. Elastic engineering team within Enablement
1. vendor issue tracker: https://gitlab.com/gitlab-com/gl-infra/elastic/issues
1. Slack channel `g_search`
1. Discussions in different issues across multiple projects (e.g. regarding costs for indexing entire gitlab.com)
1. Discussions in PM&Engineering meetings

## Historical notes ##

1. [esc-tools](https://ops.gitlab.net/gitlab-com/gl-infra/gitlab-restore/esc-tools) repo used for managing the ES5 cluster

# How-to guides #

## Upgrade checklist

This is an early-stage placeholder for tasks required for an Elasticsearch upgrade.

Pre-flight:

* TBD

Upgrade:

* TBD

After the upgrade:

* [ ] Update `managed-objects/$env/apm-*_template.json` to point to new APM version.

## Performing operations on the Elastic cluster ##

One time Elastic operations should be documented as `api_call` s in this repo. Everything else, for example cluster config, index templates, should be managed using CI (with the exception of dashboards and visualizations created in Kibana by users).

## Estimating Log Volume and Cluster Size

If we know how much log volume we are indexing per day, how many resources we
are using on our cluster, the desired retention period and how much log volume
we want to add, then we can estimate the needed cluster size.

Currently, fluentd is sending all logs to stackdriver and some logs to GCP
PubSub. We have pubsubbeat nodes for each topic, sending the logs into elastic.

### What is going to Stackdriver?

Stackdriver is ingesting everything - around **50TiB** per month as of 17-01-2020: [Resources
view](https://console.cloud.google.com/logs/usage?authuser=1&project=gitlab-production)

[haproxy logs](https://console.cloud.google.com/monitoring/metrics-explorer?pageState=%7B%22xyChart%22:%7B%22dataSets%22:%5B%7B%22timeSeriesFilter%22:%7B%22filter%22:%22metric.type%3D%5C%22logging.googleapis.com%2Fexports%2Fbyte_count%5C%22%20resource.type%3D%5C%22logging_sink%5C%22%20resource.label.%5C%22name%5C%22%3D%5C%22haproxy_logs%5C%22%22,%22perSeriesAligner%22:%22ALIGN_RATE%22,%22crossSeriesReducer%22:%22REDUCE_NONE%22,%22secondaryCrossSeriesReducer%22:%22REDUCE_NONE%22,%22minAlignmentPeriod%22:%2260s%22,%22groupByFields%22:%5B%5D,%22unitOverride%22:%22By%22%7D,%22targetAxis%22:%22Y1%22,%22plotType%22:%22LINE%22%7D%5D,%22options%22:%7B%22mode%22:%22COLOR%22%7D,%22constantLines%22:%5B%5D,%22timeshiftDuration%22:%220s%22,%22y1Axis%22:%7B%22label%22:%22y1Axis%22,%22scale%22:%22LINEAR%22%7D%7D,%22isAutoRefresh%22:true,%22timeSelection%22:%7B%22timeRange%22:%221w%22%7D%7D&project=gitlab-production)
are send into a GCP sink instead of to pubsub/elastic because of their
size (10MiB/s or **850GiB/day**).

### What is the Volume of our PubSub topics?

[Average daily pubsub volume per topic in GiB](https://thanos-query.ops.gitlab.net/graph?g0.range_input=2w&g0.max_source_resolution=0s&g0.expr=avg_over_time(stackdriver_pubsub_topic_pubsub_googleapis_com_topic_byte_cost%7Benv%3D%22gprd%22%7D%5B1d%5D)*60*24%2F1024%2F1024%2F1024&g0.tab=0)
(base unit in prometheus is Byte/minute for this metric).

[Same metric in Stackdriver metrics explorer](https://console.cloud.google.com/monitoring/metrics-explorer?authuser=1&project=gitlab-production&pageState=%7B%22xyChart%22:%7B%22dataSets%22:%5B%7B%22timeSeriesFilter%22:%7B%22filter%22:%22metric.type%3D%5C%22pubsub.googleapis.com%2Ftopic%2Fbyte_cost%5C%22%20resource.type%3D%5C%22pubsub_topic%5C%22%22,%22perSeriesAligner%22:%22ALIGN_RATE%22,%22crossSeriesReducer%22:%22REDUCE_NONE%22,%22secondaryCrossSeriesReducer%22:%22REDUCE_NONE%22,%22minAlignmentPeriod%22:%2260s%22,%22groupByFields%22:%5B%5D,%22unitOverride%22:%22By%22%7D,%22targetAxis%22:%22Y1%22,%22plotType%22:%22LINE%22%7D%5D,%22options%22:%7B%22mode%22:%22COLOR%22%7D,%22constantLines%22:%5B%5D,%22timeshiftDuration%22:%220s%22,%22y1Axis%22:%7B%22label%22:%22y1Axis%22,%22scale%22:%22LINEAR%22%7D%7D,%22isAutoRefresh%22:true,%22timeSelection%22:%7B%22timeRange%22:%221m%22%7D%7D) (Byte/s)

Total of **1.3TiB/day** as of 17-01-2020 (nginx being excluded).

### How much elastic storage are we using per day?

As we have one index alias per pubsub topic and in ES5 cluster (`gitlab-production`) we use a naming convention for
rolled-over indices to add the date and a counter, we can grep the elastic cat
api for each pubsub index alias and add together the size of all indices
belonging to the same alias with the same day in the name to get the daily index
volume.  [../api_calls/single/get-index-stats-summary.sh]
is doing that for you.

The results as of 16-01-2020 are analyzed in
[this sheet](https://docs.google.com/spreadsheets/d/1RN7Ry2pI7iTFURqb0G5zjhNp7xkiPSVG-YsoBOO3TFw).

**We can conclude from this, that index volume (with one replica shard) is around
3 times the volume of the corresponding pubsub topic.**

As of 17-01-2020 we are using ca. **4TiB elastic storage per day** (only pubsub topics, excluding
nginx). That means for a **7 day retention** we consume around 28TiB storage. Adding
nginx logs would increase that by 0.6TiB/day (15%), haproxy logs by 2.5TiB/day (63%).

## Analyzing index mappings

At the moment of writing, we utilize static mappings defined in this repository. Here are a few ideas for analysis of those mappings:
```bash
$ jsonnet elastic/managed-objects/lib/index_mappings/rails.jsonnet | jq -r 'leaf_paths|join(".")' | grep -E '\.type$' | wc -l
$ jsonnet elastic/managed-objects/lib/index_mappings/rails.jsonnet | jq -r 'leaf_paths|join(".")' | grep -E '\.type$' | head
$ jsonnet elastic/managed-objects/lib/index_mappings/rails.jsonnet | jq -r 'leaf_paths|join(";")' | grep -E ';type$' | awk '{ print $1, 1 }' | inferno-flamegraph > mapping_rails.svg
```

# Concepts #

## Elastic learning materials ##

## Design Document (Elastic at Gitlab) ##

https://gitlab.com/gitlab-com/www-gitlab-com/merge_requests/23545
TODO: update this link once merged

## Monitoring ##

Because Elastic Cloud is running on infrastructure that we do not manage or have access to, we cannot use our exporters/Prometheus/Thanos/Alertmanager setup. For this reason, the best option is to use Elasticsearch built-in x-pack monitoring that is storing monitoring metrics in Elasticsearch indices. In production environment, it makes sense to use a separate cluster for storing monitoring metrics (if metrics were stored on the same cluster, we wouldn't know the cluster is down because monitoring would be down as well).

When monitoring is enabled and configured to send metrics to another Elastic cluster, it's the receiving clusters' responsibility to handle metrics rotation, i.e. the receiving cluster needs to have retention configured. For more details see: https://www.elastic.co/guide/en/cloud/current/ec-enable-monitoring.html#ec-monitoring-retention  and https://www.elastic.co/guide/en/elasticsearch/reference/current/monitoring-settings.html

Apart from monitoring using x-pack metrics + watches, we are also using a blackbox exporter in our infrastructure. It's used for monitoring selected API endpoints, such as ILM explain API.

## Alerting ##

Since we cannot use our Alertmanager, Elasticsearch Watches have to be used for alerting. They will be configured on the Elastic cluster used for storing monitoring indices.

Blackbox probes cannot provide us with sufficient granularity of state reporting.

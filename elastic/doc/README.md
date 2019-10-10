<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Quick start](#quick-start)
    - [Elastic related resources](#elastic-related-resources)
- [How-to guides](#how-to-guides)
    - [Performing operations on the Elastic cluster (esc-tools)](#performing-operations-on-the-elastic-cluster-esc-tools)
- [Concepts](#concepts)
    - [Elastic learning materials](#elastic-learning-materials)
    - [Design Document (Elastic at Gitlab)](#design-document-elastic-at-gitlab)
    - [Monitoring](#monitoring)
    - [Alerting](#alerting)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Quick start

## Elastic related resources ##

1. [Logging dashboard in Grafana](https://dashboards.gitlab.net/d/USVj3qHmk/logging?orgId=1&from=now-7d&to=now)
1. [esc-tools](https://ops.gitlab.net/gitlab-com/gl-infra/gitlab-restore/esc-tools)
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
1. Slack channel `f_elastic-search`
1. Discussions in different issues across multiple projects (e.g. regarding costs for indexing entire gitlab.com)
1. Discussions in PM&Engineering meetings

# How-to guides #

## Performing operations on the Elastic cluster (esc-tools) ##

Elastic operations should be documented as bash scripts in the [esc-tools repo](https://ops.gitlab.net/gitlab-com/gl-infra/gitlab-restore/esc-tools)

# Concepts #

## Elastic learning materials ##

## Design Document (Elastic at Gitlab) ##

https://gitlab.com/gitlab-com/www-gitlab-com/merge_requests/23545
TODO: update this link once merged

## Monitoring ##

Because Elastic Cloud is running on infrastructure that we do not manage or have access to, we cannot use our exporters/Prometheus/Thanos/Alertmanager setup. For this reason, the best option is to use Elasticsearch built-in monitoring that is storing monitoring metrics in Elasticsearch indices. In production environment, it makes sense to use a separate cluster for storing monitoring metrics (if metrics were stored on the same cluster, we wouldn't know the cluster is down because monitoring would be down as well).

When monitoring is enabled and configured to send metrics to another Elastic cluster, it's the receiving clusters' responsibility to handle metrics rotation, i.e. the receiving cluster needs to have retention configured. For more details see: https://www.elastic.co/guide/en/cloud/current/ec-enable-monitoring.html#ec-monitoring-retention  and https://www.elastic.co/guide/en/elasticsearch/reference/current/monitoring-settings.html

## Alerting ##

Since we cannot use our Alertmanager, Elasticsearch Watchers have to be used for alerting. They will be configured on the Elastic cluster used for storing monitoring indices.

Blackbox probes cannot provide us with sufficient granularity of state reporting.

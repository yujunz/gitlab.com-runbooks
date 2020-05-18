<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Troubleshooting](#troubleshooting)
    - [Elastic](#elastic)
        - [How to check cluster health](#how-to-check-cluster-health)
        - [How to check cluster logs](#how-to-check-cluster-logs)
        - [Running commands directly against the API](#running-commands-directly-against-the-api)
        - [esc-tools scripts](#esc-tools-scripts)
            - [get shards allocation errors](#get-shards-allocation-errors)
            - [get shards allocation](#get-shards-allocation)
            - [get number of threads](#get-number-of-threads)
            - [get current node allocation](#get-current-node-allocation)
        - [past incidents](#past-incidents)
            - [Ideas of things to check (based on previous incidents)](#ideas-of-things-to-check-based-on-previous-incidents)
            - [high CPU load on a single node](#high-cpu-load-on-a-single-node)
            - [cluster lags behind with logs after a node was added](#cluster-lags-behind-with-logs-after-a-node-was-added)
            - [too many active shards on a single node](#too-many-active-shards-on-a-single-node)
            - [running out of disk space](#running-out-of-disk-space)
        - [Cluster unhealthy](#cluster-unhealthy)
        - [Shard Allocation Failure](#shard-allocation-failure)
            - [shards unassigned](#shards-unassigned)
            - [shards unavailable (cluster unhealthy)](#shards-unavailable-cluster-unhealthy)
            - [shards too big](#shards-too-big)
    - [Index Lifecycle Management (ILM)](#index-lifecycle-management-ilm)
        - [Failure to move an index from a hot node to a warm node](#failure-to-move-an-index-from-a-hot-node-to-a-warm-node)
    - [Saturation response](#saturation-response)
- [Failover and Recovery procedures](#failover-and-recovery-procedures)
    - [Elastic](#elastic-1)
        - [delete an index](#delete-an-index)
        - [retry shard allocation](#retry-shard-allocation)
        - [moving shards between nodes](#moving-shards-between-nodes)
        - [restarting an ES deployment](#restarting-an-es-deployment)
        - [remove oldest indices](#remove-oldest-indices)
        - [Fixing conflicts in index mappings](#fixing-conflicts-in-index-mappings)
    - [Index Lifecycle Management (ILM)](#index-lifecycle-management-ilm-1)
        - [Index Roll-over Failure](#index-roll-over-failure)
        - [retry ILM for indices with errors](#retry-ilm-for-indices-with-errors)
        - [mark index as complete](#mark-index-as-complete)
        - [force index rollover](#force-index-rollover)
        - [start ILM](#start-ilm)
    - [Kibana](#kibana)
        - [refreshing index mappings cache](#refreshing-index-mappings-cache)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Troubleshooting

## Elastic

### How to check cluster health

TODO investigate the difference between stats reported in the monitoring cluster and elastic cloud web UI

Elastic cloud clusters' performance can be checked using a few interfaces. They are listed below in the order of most likely availability and usefulness, but if one method is broken try another:
- in Kibana, in the monitoring cluster (you can also find these links in the deployment page, in the Elastic Cloud web UI):
    - [logging prod and nonprod monitoring cluster](https://00a4ef3362214c44a044feaa539b4686.us-central1.gcp.cloud.es.io:9243/) credentials in 1password, Vault: Production, Login entry called: "ElasticCloud gitlab-logs-monitoring"
    - [indexing prod monitoring cluster](https://0377b39ab1394c659c2714aca44756ea.us-central1.gcp.cloud.es.io:9243/) credentials in 1password, Vault: Production, Login entry called: "ElasticCloud prod-gitlab-com_indexing_monitoring"
    - [indexing staging monitoring cluster](https://78fcbb399b4a4a4784a1ccb8b7da2712.us-central1.gcp.cloud.es.io:9243/) credentials in 1password, Vault: Production, Login entry called: "ElasticCloud staging-gitlab-com_indexing_monitoring"
- in Kibana, in the cluster itself if it's configured for self-monitoring (at the moment of writing only short-lived, test clusters are configured for self-monitoring)
- ElasticCloud web UI (on the deployment page -> Performance)
- Elastic API
- kopf (deprecated in newer versions of ES):
    - gitlab-logs-prod: https://022d92a4ba7ff6fdacc2a7182948cb0a.us-central1.gcp.cloud.es.io:9243/_found.no/dashboards/kopf/latest/?location=https://022d92a4ba7ff6fdacc2a7182948cb0a.us-central1.gcp.cloud.es.io:9243#!/cluster
    - credentials are in 1password

### How to check cluster logs

The only logs available to us are available in the Elastic Cloud Web UI.

To view them, go to the deployments page and click on "Logs" on the left hand side.

### Running commands directly against the API ###

you can query the API using:
- Kibana
- Elastic Cloud web UI (`API Console` on the left)
- bash + curl
- Curator
- other tools (e.g. Postman)

Credentials for APIs are in 1password (for all clusters the admin username is: elastic)

### esc-tools scripts

Scripts that are available in [esc-tools repo](https://ops.gitlab.net/gitlab-com/gl-infra/gitlab-restore/esc-tools/tree/master) and are useful for troubleshooting

#### get shards allocation errors ####

#### get shards allocation ####

#### get number of threads ####

#### get current node allocation ####

### past incidents ###

#### Ideas of things to check (based on previous incidents) ####

on ES cluster:
- do the nodes have enough disk space?
- are shards being moved at the moment?
- are all shards allocated? or are there any shard allocation errors?
- what's the indexing latency? (if it's high, there's a problem with performance)
- what's the cpu/memory/io usage?

#### high CPU load on a single node ####

See [below](#too-many-active-shards-on-a-single-node)

#### cluster lags behind with logs after a node was added ####

See [below](#too-many-active-shards-on-a-single-node)

#### too many active shards on a single node ####

As the new node is starting with no assigned shards, it will get all new shards
assigned after a rollover, resulting in hot-spotting. We used high cpu usage as
an indicator, but it was based on a guess (there was no hard evidence showing
the cpu was used by processes related to shards).

Solution:  See [retry shard allocation](#retry-shard-allocation)

#### running out of disk space ####

for different reasons:
- too much data
- rebalancing taking place

storage usage in the web UI was in red and the absolute value was high (e.g. 99%)

We plan to alert on that: https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/8548

### Cluster unhealthy

`_cluster/health` endpoint returns anything other than `green`.

We have alerts for the production logging cluster:
https://gitlab.com/gitlab-com/runbooks/blob/master/rules/elastic-clusters.yml#L24-33
and monitoring cluster:
https://gitlab.com/gitlab-com/runbooks/blob/master/rules/elastic-clusters.yml#L44-53
being in a state other than `green`.

### Shard Allocation Failure

In the past we saw this happen in multiple scenarios. Here are a few examples:

 - an ILM policy has requirements that no node can meet (there is no prior
   indication of that)
 - max allocation retry limit was reached, allocation was stopped and never
   retried (for example when a cluster is unhealthy and recovers by itself)
 - storage watermarks on nodes were reached (the scheduler will refuse to
   allocate shards to those nodes)
 - read-only blocks on node/cluster

#### shards unassigned ####

for different reasons:
- no eligible nodes
- pulled back kicked in (there is a pull back mechanism in ES, i.e. after a few failed attempts to assign shards Elastic will stop trying)
- see https://www.datadoghq.com/blog/elasticsearch-unassigned-shards/ for a
  detailed explanation of possible reasons

finding unassigned shards:
[api_calls/single/get-unassigned-shards.sh](../../api_calls/single/get-unassigned-shards.sh)

#### shards unavailable (cluster unhealthy) ####

This happens if both primary and replica for a shard are not available. Most
probable reason is failure to allocate shards because of missing storage
capacity. In this case deleting the affected index is the easiest way to come
back to a healthy state.

- find unassigned shards: [api_calls/single/get-unassigned-shards.sh](../../api_calls/single/get-unassigned-shards.sh)
- identify shards where both primary (`p`) and replica (`r`) are unassigned
- delete the affected index if it's a few days old already

#### shards too big ####

https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/7398

## Index Lifecycle Management (ILM)

- in Kibana, go to: Management -> Index Management -> if there are ILM errors there will be a notification box displayed above the search box
- in Elastic Cloud web UI:
  - check Elastic logs for any errors
- in the monitoring cluster:
  - check cluster health
  - check indices sizes and confirm they are within the policy

for more docs see [Index Lifecycle Management](../../logging/doc/README.md#index-lifecycle-management-ilm)


### Failure to move an index from a hot node to a warm node ###

This can happen for example when warm nodes run out of disk space. The ILM step will fail and mark the index as read-only. Clusters health will turn to unhealthy with an error message:
```
"An Elasticsearch index is in a read-only state and only allows deletes"
```

Any subsequent ILM attempts will fail with the following error message:
```
blocked by: [FORBIDDEN/12/index read-only / allow delete (api)];
```

In order to fix:
- Release space on warm nodes (do not resize the cluster as it will fail!). Disk space can be released by removing indices. When deciding which indices to remove, start with oldest ones.
- Remove blocks from indices that failed (if the entire cluster has been marked as read-only, remove that block as well). API calls for removing blocks (from indices and from the cluster) are documented in this repo, in the [scripts](../../scripts/) directory.
- Retry ILM steps
- Once the cluster is back in a healthy state, adjust ILM policy or resize the cluster

## Saturation response

Usually, our response to the following alerts is to consider scaling the cluster
out.

# Failover and Recovery procedures #

## Elastic

### delete an index ###

### retry shard allocation ###

### moving shards between nodes ###

- if shards are distributed unequally, one node might receive a disproportionate amount of traffic causing high CPU usage and as a result the indexing latency might go up
- stop routing to the overloaded node and force an index rollover (incoming documents are only saved to new indeces, regardless of the timestamp in the document)
- alternatively you can trigger shard reballancing -> this might actually not be such a good idea. If the node is already heavily loaded, making it move a shard, which uses even more resources, will only make things worse.

```
NODE=instance-0000000016
# find small inactive shards on other nodes:
curl -u 'xxx:yyy' "https://<deployment-id>.us-central1.gcp.cloud.es.io:9243/_cat/shards?v&bytes=b&h=store,index,node,shard,p,state" | grep -v $NODE | sort -r

# find active shards on overloaded node (last number is index operations -
# take shards with more than 0 index operations):
curl -u 'xxx:yyy' "https://<deployment-id>.us-central1.gcp.cloud.es.io:9243/_cat/shards?v&bytes=b&h=store,index,node,shard,p,state,iic&s=iic,store" | grep $NODE

# create file move.json with shards to move around:
{
    "commands" : [{
            "move" : {
                "index" : "pubsub-consul-inf-gprd-2020.01.26-000007", "shard" : 3,
                "from_node" : "instance-0000000072", "to_node" : "instance-0000000016"
            }
     },
     {
            "move" : {
                "index" : "pubsub-rails-inf-gprd-2020.01.29-000007", "shard" : 0,
                "from_node" : "instance-0000000016", "to_node" : "instance-0000000072"
            }
     }]
}

# Post the change:
curl -XPOST -u 'xxx:yyy' -d @move.json https://<deployment-id>.us-central1.gcp.cloud.es.io:9243/_cluster/reroute?retry_failed=true

# this may fail if shards are not placed according to allocation constraints,
# e.g. all shards of an index should end up on different nodes. Try again with
# different shards or nodes.
```


### restarting an ES deployment ###

### remove oldest indices ###

### Fixing conflicts in index mappings ###

In ES7 we rely on dynamic mappings set by the cluster. These mappings are set when the first document arrives at the cluster. If the type of a field is incorrectly detected, the cluster will fail to parse subsequent documents and will refuse to index them. The fix is to set mappings statically in those cases.

Here's an example of a static mapping set for `json.args`: https://gitlab.com/gitlab-com/runbooks/merge_requests/1782

Once the index templates are updated (the above MR is merged and CI job successfully uploaded templates) you'll also need to [force a rollover of indices](../../api_calls/single/force-index-rollover.sh) and [mark the old index as complete](mark-index-complete.sh).

## Index Lifecycle Management (ILM)

### Index Roll-over Failure

Can be caused by:

  - ILM errors (this can happen for a number of reasons, here's an example bug
    that leads to ILM errors:
    https://github.com/elastic/elasticsearch/issues/44175)
  - ILM stopped (the cluster remains healthy, but no indices are rolled over and
    there is no indicator of that happening until nodes run out of disk space at
    which point shards can be multiple TBs in size)
  - reaching storage watermarks (which causes ILM failures and the index is
    never rolled over and it continues to grow causing disk usage to grow
    indefinitely despite the node reaching watermarks and there is nothing
    stopping it from reaching 100% disk usage at which point indices **have to
    be dropped**)

### retry ILM for indices with errors

Our response to "ILM errors" alerts is to investigate the cause for the errors and retry ILM on indices that failed. In order to retry ILM on failed indices:
- Kibana -> Management pane (on the left hand side) -> Index Management -> if there are any lifecycle errors click on the "Show errors"
- Select all indices with ILM errors
- Manage index -> Retry ILM steps

You can also do it in a loop using a bash script available at `elastic/api_calls/batch/retry-ilm.sh`.

### mark index as complete ###

### force index rollover ###

### start ILM

In certain scenarios ILM can end up in a stopped state. In order to start it again:
1. issue an http request to the Elastic API (e.g. using Kibana console): `POST /_ilm/start`
1. Make sure no indices have `read_only` blocks:
  - Kibana -> Management pane (on the left hand side) -> Index Management -> if there are any lifecycle errors click on the "Show errors"
  - click on each index on the list (of indices with errors) and read the error message
  - if any of the error message are about indices having a `read_only` block, remove the block using an api call described in `runbooks/elastic/api_calls/single/remove-read_only_allow_delete-block-from-an-index.sh`
  - trigger ILM retry on the index using Kibana
1. Confirm ILM is operational again
  - make sure indices are rolled over and moved from hot nodes to warm nodes, an indication of ILM not working is uncontrollable increase in the size of the indices and the suffix not changing
1. In critical situations, you might need to remove indices forcefully

## Kibana ##

### refreshing index mappings cache ###

Example error message:
```
illegal_argument_exception

Fielddata is disabled on text fields by default. Set fielddata=true on [json.extra.since] in order to load fielddata in memory by uninverting the inverted index. Note that this can however use significant memory. Alternatively use a keyword field instead.
```

In some cases, log records have an inconsistent structure which results in mapping conflicts. This can result in search queries failing on a subset of shards. When that happens, searches using Kibana fail.

The short term solution is to refresh index mappings cached in Kibana. This can be done by going to: Kibana -> Management -> Index Patterns -> select an index pattern -> click "Refresh field list" in the top right corner of the page

Long term we would like to have more consistency in logging fields so that we can avoid mapping conflicts completely.

see: https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/9364 for more details.

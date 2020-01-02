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
            - [too many active shards on a single node](#too-many-active-shards-on-a-single-node)
            - [running out of disk space](#running-out-of-disk-space)
            - [shards unassigned](#shards-unassigned)
            - [shards unavailable (cluster unhealthy)](#shards-unavailable-cluster-unhealthy)
            - [shards too big](#shards-too-big)
    - [Index Lifecycle Management (ILM)](#index-lifecycle-management-ilm)
        - [Failure to move an index from a hot node to a warm node](#failure-to-move-an-index-from-a-hot-node-to-a-warm-node)
- [Failover and Recovery procedures](#failover-and-recovery-procedures)
    - [Elastic](#elastic-1)
        - [delete an index](#delete-an-index)
        - [retry shard allocation](#retry-shard-allocation)
        - [moving shards between nodes](#moving-shards-between-nodes)
        - [restarting an ES deployment](#restarting-an-es-deployment)
        - [remove oldest indices](#remove-oldest-indices)
    - [Index Lifecycle Management (ILM)](#index-lifecycle-management-ilm-1)
        - [esc-tools](#esc-tools)
            - [mark index as complete](#mark-index-as-complete)
            - [force index rollover](#force-index-rollover)

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

#### too many active shards on a single node ####

resulting in hot-spotting, we used high cpu usage as an indicator, but it was based on a guess (there was no hard evidence showing the cpu was used by processes related to shards)

#### running out of disk space ####

for different reasons:
- too much data
- rebalancing taking place

storage usage in the web UI was in red and the absolute value was high (e.g. 99%)

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


# Failover and Recovery procedures #

## Elastic

### delete an index ###

### retry shard allocation ###

### moving shards between nodes ###

- if shards are distributed unequally, one node might receive a disproportionate amount of traffic causing high CPU usage and as a result the indexing latency might go up
- stop routing to the overloaded node and force an index rollover (incoming documents are only saved to new indeces, regardless of the timestamp in the document)
- alternatively you can trigger shard reballancing -> this might actually not be such a good idea. If the node is already heavily loaded, making it move a shard, which uses even more resources, will only make things worse.

### restarting an ES deployment ###

### remove oldest indices ###

## Index Lifecycle Management (ILM)

### esc-tools

#### mark index as complete ####

#### force index rollover ####

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Find an optimal size for a cluster that will be able to consume logs from one of the production Pub/Subs](#find-an-optimal-size-for-a-cluster-that-will-be-able-to-consume-logs-from-one-of-the-production-pubsubs)
- [resize the cluster](#resize-the-cluster)
- [trigger reallocation of failed shards](#trigger-reallocation-of-failed-shards)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Find an optimal size for a cluster that will be able to consume logs from one of the production Pub/Subs

- create a minimal deployment in Elastic Cloud, enable monitoring, forward monitoring metrics to the monitoring cluster
- make a change in terraform to create a pubsubbeat VM and a subscription
- configure pubsubbeat with credentials for the Elastic Cloud deployment
- silence alerts in alertmanager
- initialize the cluster (create ILM policy, templates, etc)
- observe the cluster health in the monitoring cluster
- resize the cluster and fix any errors with indices, unallocated shards, ILM errors

# resize the cluster

# trigger reallocation of failed shards

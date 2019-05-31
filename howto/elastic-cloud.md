# Elastic Cloud

**Elastic Vendor Tracker**: https://gitlab.com/gitlab-com/gl-infra/elastic/issues

Instead of hosting our own elastic search cluster we are using a cluster managed by elastic.co. Our logs are forwarded to it via pubsub beat (see [howto/logging.md](howto/logging.md)).

Current capacity:
* 3 zones
* 5 nodes per zone (total 15)
* 64GiB RAM, 1.5TiB storage per node

## Configure Storage Watermarks

When reaching the storage low-watermark on a node, shards will be moved to another node but if all nodes have reached the low-watermark, the cluster will stop storing any data. As per suggestion from Elastic (https://gitlab.com/gitlab-com/gl-infra/production/issues/616#note_124839760) we should use absolute byte values instead of percentages for setting the watermarks and, given the actual shard sizes, we should leave enough headroom for writing to shards, segment merging and node failure.

Current configuration:
* high watermark: 200gb
* low watermark: 150gb

(I believe `gb` means GiB, but can't find a reference.)

### Setting Storage Watermarks

```
PUT _cluster/settings
{
  "persistent": {
    "cluster.routing.allocation.disk.watermark.low": "200gb",
    "cluster.routing.allocation.disk.watermark.high": "150gb"
  }
}
```


## Resizing cluster ##

### adding new availability zones ###

https://www.elastic.co/guide/en/cloud-enterprise/current/ece-resize-deployment.html

adding and removing availability zones was tested. elastic.co decides whether to have a dedicated VM for master or to nominate master from among the data nodes. The number of availability zones determines in how many zones there will be data nodes (you might actually end up with more VMs if elastic.co decides to run master on a dedicated node).

### resizing instances ###

The way it works is new machines are created with the desired spec, they are then brought online, shards are moved across and once that is complete the old ones are taken offline and removed. This worked very smoothly.

we can scale up and down. resizing is done live.

## Monitoring ##

Because Elastic Cloud is running on infrastructure that we do not manage or have access to, we cannot use our exporters/Prometheus/Thanos/Alertmanager setup. For this reason, the only available option is to use Elasticsearch built-in monitoring that is storing monitoring metrics in Elasticsearch indices. In production environment, it makes sense to use a separate cluster for storing monitoring metrics (if metrics were stored on the same cluster, we wouldn't know the cluster is down because monitoring would be down as well).

## Alerting ##

Since we cannot use our Alertmanager, Elasticsearch Watchers have to be used for alerting. They will be configured on the Elastic cluster used for storing monitoring indices.

blackbox probes cannot provide us with sufficient granularity of state reporting.

# Elastic Cloud

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
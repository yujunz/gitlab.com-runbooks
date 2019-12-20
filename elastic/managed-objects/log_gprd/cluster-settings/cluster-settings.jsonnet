{
  persistent: {
    // https://www.elastic.co/guide/en/elasticsearch/reference/current/disk-allocator.html
    // When reaching the storage low-watermark on a node, shards will be no longer be assigned to that node but if all nodes have reached the low-watermark, the cluster will stop storing any data. As per suggestion from Elastic (https://gitlab.com/gitlab-com/gl-infra/production/issues/616#note_124839760) we should use absolute byte values instead of percentages for setting the watermarks and, given the actual shard sizes, we should leave enough headroom for writing to shards, segment merging and node failure.
    // (I believe `gb` means GiB, but can't find a reference)
    'cluster.routing.allocation.disk.watermark.low': '85%',
    'cluster.routing.allocation.disk.watermark.high': '90%',
    'cluster.routing.allocation.disk.watermark.flood_stage': '95%',
    'index.routing.allocation.total_shards_per_node': '6',
  },
}

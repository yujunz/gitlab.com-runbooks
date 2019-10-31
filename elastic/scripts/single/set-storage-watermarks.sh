#!/bin/bash

# When reaching the storage low-watermark on a node, shards will be moved to another node but if all nodes have reached the low-watermark, the cluster will stop storing any data. As per suggestion from Elastic (https://gitlab.com/gitlab-com/gl-infra/production/issues/616#note_124839760) we should use absolute byte values instead of percentages for setting the watermarks and, given the actual shard sizes, we should leave enough headroom for writing to shards, segment merging and node failure.

# (I believe `gb` means GiB, but can't find a reference.)

curl_data_watermark() {
  cat <<EOF
{
    "persistent": {
        "cluster.routing.allocation.disk.watermark.low": "200gb",
        "cluster.routing.allocation.disk.watermark.high": "150gb"
    }
}
EOF
}

curl -sSL -H 'Content-Type: application/json' -X PUT "${ES7_URL_WITH_CREDS}/_cluster/settings" -d "$(curl_data_watermark)"

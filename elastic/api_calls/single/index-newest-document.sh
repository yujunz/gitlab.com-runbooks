#!/bin/bash
# estimate when an index was rolled over by looking at the newest document
# useful for getting a measure of "index age".
#
# example usage: ./index-rollover-time.sh pubsub-workhorse-inf-gprd-002229

set -eufo pipefail
IFS=$'\t\n'
index=$1

curl_data() {
  cat <<EOF
POST
{
  "aggs": {
    "max_time": { "max": { "field": "json.time" } }
  }
}
EOF
}

curl -sSL -H 'Content-Type: application/json' -X PUT "${ES7_URL_WITH_CREDS}/${index}/_search?size=0" -d "$(curl_data)"

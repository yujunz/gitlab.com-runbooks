#!/bin/bash

set -eufo pipefail

curl_data() {
  cat <<EOF
{
    "persistent": {
        "xpack.monitoring.history.duration": "7d"
    }
}
EOF
}

curl -sSL -H 'Content-Type: application/json' -X PUT "${ES7_URL_WITH_CREDS}/_cluster/settings" -d "$(curl_data)"

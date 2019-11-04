#!/bin/bash

set -eufo pipefail

index=$1

curl_data() {
  cat <<EOF
{
    "index": {
        "blocks": {
            "read_only_allow_delete": "false"
        }
    }
}
EOF
}

curl -sSL -H 'Content-Type: application/json' -X PUT "${ES7_URL_WITH_CREDS}/${index}/_settings" -d "$(curl_data)"

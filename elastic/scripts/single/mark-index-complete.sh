#!/bin/bash

set -eufo pipefail

index=$1

curl_data_settings() {
  cat <<EOF
{
    "index": {
        "lifecycle": {
            "indexing_complete": "true"
        }
    }
}
EOF
}

curl -sSL -X PUT -H 'Content-Type: application/json' "${ES7_URL_WITH_CREDS}/${index}/_settings" -d "$(curl_data_settings)"

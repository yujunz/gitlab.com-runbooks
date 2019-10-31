#!/bin/bash

set -eufo pipefail

index=$1

curl_data() {
  cat <<EOF
{
    "conditions": {
        "max_age": "1m"
    }
}
EOF
}

curl -sSL -H 'Content-Type: application/json' -X POST "${ES7_URL_WITH_CREDS}/${index}/_rollover" -d "$(curl_data)"

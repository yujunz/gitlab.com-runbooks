#!/bin/bash

set -eufo pipefail
IFS=$'\t\n'

src_index=$1
dest_index="${src_index}-1"
alias=$(curl -sSL -X GET "${ES7_URL_WITH_CREDS}/${src_index}" | jq '[.. | objects | with_entries(select(.key | contains("aliases"))) | select(. != {}) ]' | jq -r '.[].aliases | keys[]')

echo "$src_index"
echo "$dest_index"
echo "$alias"
echo ""

curl_data_create_dest() {
  cat <<EOF
{
    "aliases": {
        "${alias}": {}
    }
}
EOF
}

echo 'see warning in the script!!!!!!!!!!!!!!'
# Last time this script was used, the indices created had ILM policy assigned to them which resulted in two indices being writeable in the same alias (which results in ILM errors). In order to avoid this, consider not setting alias when creating the index. This change was not applied to the script because it would have to be tested thoroughly first

echo 'creating dest'
curl -sSL -H 'Content-Type: application/json' -X PUT "${ES7_URL_WITH_CREDS}/${dest_index}" -d "$(curl_data_create_dest)"

curl_data_reindex() {
  cat <<EOF
{
    "source": {
        "index": "${src_index}"
    },
    "dest": {
        "index": "${dest_index}"
    }
}
EOF
}

echo ''
echo 'triggering reindexing'
curl -sSL -H 'Content-Type: application/json' -X POST "${ES7_URL_WITH_CREDS}/_reindex" -d "$(curl_data_reindex)"

echo ''

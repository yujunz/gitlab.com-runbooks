#!/bin/bash
# get mappings for an index, print them in a jsonnet compatible format

set -eufo pipefail
IFS=$'\t\n'
index=$1

curl -sSL -H 'Content-Type: application/json' -X GET "${ES7_URL_WITH_CREDS}/${index}/_mappings" | jq '.[].mappings' | jsonnetfmt -

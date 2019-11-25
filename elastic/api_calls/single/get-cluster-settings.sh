#!/bin/bash

set -eufo pipefail

# curl -sSL -X GET "${ES7_URL_WITH_CREDS}/_cluster/settings" | jq
curl -sSL -X GET "${ES7_URL_WITH_CREDS}/_cluster/settings?include_defaults=true" | jq

#!/bin/bash

set -eufo pipefail

curl -sSL "${ES7_URL_WITH_CREDS}/_cluster/allocation/explain?pretty" | jq

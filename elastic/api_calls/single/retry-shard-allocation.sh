#!/bin/bash

set -eufo pipefail

curl -sSL -X POST "${ES7_URL_WITH_CREDS}/_cluster/reroute?retry_failed=true"

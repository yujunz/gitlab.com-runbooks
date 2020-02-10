#!/usr/bin/env bash
set -euo pipefail
set -x
url="https://log-proxy:*****@e8eb2b813ecf40e3ab39829e7cd3a4d9.us-central1.gcp.cloud.es.io"
index_pattern="$1"
# Create index pattern
# curl -f to fail on error
curl -f -XDELETE -H "Content-Type: application/json" -H "kbn-xsrf: anything" \
  "$url/api/saved_objects/index-pattern/$index_pattern"

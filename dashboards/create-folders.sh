#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

curl --silent --fail \
    -H "Authorization: Bearer $GRAFANA_API_TOKEN" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    "https://dashboards.gitlab.net/api/folders/" \
    -d'
{
  "uid": "general",
  "title": "General Metrics"
}
'

#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Install dependencies
if ! [[ -d "${SCRIPT_DIR}/grafonnet-lib" ]]; then
  git clone https://github.com/grafana/grafonnet-lib.git "${SCRIPT_DIR}/grafonnet-lib"
fi

# Install jsonnet dashboards
find "${SCRIPT_DIR}" -name '*.dashboard.jsonnet'|while read -r line; do
  relative=${line#"$SCRIPT_DIR/"}
  folder=$(dirname "$relative")

  folderId=$(curl --silent --fail \
    -H "Authorization: Bearer $GRAFANA_API_TOKEN" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    "https://dashboards.gitlab.net/api/folders/${folder}" | jq '.id')

  dashboard=$(jsonnet -J "${SCRIPT_DIR}" -J "${SCRIPT_DIR}/grafonnet-lib" "${line}")

  url=$(curl --silent --fail \
    -H "Authorization: Bearer $GRAFANA_API_TOKEN" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    https://dashboards.gitlab.net/api/dashboards/db \
    -d"{
    \"dashboard\": ${dashboard},
    \"folderId\": ${folderId},
    \"overwrite\": true
  }" | jq -r '.url')

  echo "Installed https://dashboards.gitlab.net${url}"
done

# Install json dashboards
find "${SCRIPT_DIR}" -name '*.dashboard.json'|while read -r line; do
  relative=${line#"$SCRIPT_DIR/"}
  folder=$(dirname "$relative")

  echo "${line}"

  folderId=$(curl --silent --fail \
    -H "Authorization: Bearer $GRAFANA_API_TOKEN" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    "https://dashboards.gitlab.net/api/folders" | jq '.[] | select(.title=='\""${folder}"\"') | .id')

  dashboard=$(cat "${line}")

  url=$(curl --silent --fail \
    -H "Authorization: Bearer $GRAFANA_API_TOKEN" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    https://dashboards.gitlab.net/api/dashboards/db \
    -d"{
    \"dashboard\": ${dashboard},
    \"folderId\": ${folderId},
    \"overwrite\": true
  }" | jq -r '.url')

  echo "Installed https://dashboards.gitlab.net${url}"
done

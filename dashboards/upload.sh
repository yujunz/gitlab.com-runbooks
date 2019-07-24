#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

find_dashboards() {
  if [[ $# == 0 ]]; then
    find "${SCRIPT_DIR}" '(' -name '*.dashboard.jsonnet' -o -name '*.dashboard.json' ')'
  else
    for var in "$@"
    do
      echo "${var}"
    done
  fi
}

# Install jsonnet dashboards
find_dashboards "$@"|while read -r line; do
  relative=${line#"$SCRIPT_DIR/"}
  folder=$(dirname "$relative")

  uid="${folder}-$(basename "$line"|sed -e 's/\..*//')"

  # Note: create folders with `create-grafana-folder.sh` to configure the UID
  folderId=$(curl --silent --fail \
    -H "Authorization: Bearer $GRAFANA_API_TOKEN" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    "https://dashboards.gitlab.net/api/folders/${folder}" | jq '.id')

  extension="${relative##*.}"
  if [[ "$extension" == "jsonnet" ]]; then
    dashboard=$(jsonnet -J "${SCRIPT_DIR}" -J "${SCRIPT_DIR}/vendor" "${line}")
  else
    dashboard=$(cat "${line}")
  fi

  current_uid=$(echo "${dashboard}" | jq -r ".uid")
  if [[ -z ${current_uid} ]] || [[ ${current_uid}  == "null" ]]; then
    # If the dashboard doesn't have a uid, configure one
    dashboard=$(echo "${dashboard}" | jq ".uid = \"$uid\"")
  fi

  response=$(curl --silent --fail \
    -H "Authorization: Bearer $GRAFANA_API_TOKEN" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    https://dashboards.gitlab.net/api/dashboards/db \
    -d"{
    \"dashboard\": ${dashboard},
    \"folderId\": ${folderId},
    \"overwrite\": true
  }") || {
    echo "Unable to install $relative"
    exit 1
  }

  url=$(echo "${response}"| jq -r '.url')
  echo "Installed https://dashboards.gitlab.net${url}"
done

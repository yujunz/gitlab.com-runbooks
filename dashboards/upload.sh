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

# Install dependencies
if ! [[ -d "${SCRIPT_DIR}/grafonnet-lib" ]]; then
  git clone https://github.com/grafana/grafonnet-lib.git "${SCRIPT_DIR}/grafonnet-lib"
fi

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
    dashboard=$(jsonnet -J "${SCRIPT_DIR}" -J "${SCRIPT_DIR}/grafonnet-lib" "${line}")
  else
    dashboard=$(cat "${line}")
  fi

  if [[ -z $(echo "${dashboard}" | jq ".uid") ]]; then
    # If the dashboard doesn't have a uid, configure one
    dashboard=$(echo "${dashboard}" | jq ".uid = \"$uid\"")
  fi

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

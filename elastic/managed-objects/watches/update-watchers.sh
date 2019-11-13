#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
source "${SCRIPT_DIR}"/../lib/update-scripts-functions.sh

for i in "${SCRIPT_DIR}"/*.json; do
  base_name=$(basename "$i")
  name=${base_name%.json}
  es_client "_xpack/watcher/watch/${name}?pretty=true" -X PUT --data-binary "@${i}"
done

for i in "${SCRIPT_DIR}"/*.jsonnet; do
  base_name=$(basename "$i")
  echo "$base_name"
  name=${base_name%.jsonnet}
  watch_json="$(execute_jsonnet "${i}" | jq -c '.')" # Compile jsonnet and compact with jq
  es_client "_xpack/watcher/watch/${name}?pretty=true" -X PUT --data-binary "${watch_json}"
done

#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

function es_client() {
  url=$1; shift
  curl --retry 3 --fail -H 'Content-Type: application/json' "${ES_URL}/${url}" "$@"
}

for i in "${SCRIPT_DIR}"/watches/*.json; do
  base_name=$(basename "$i")
  name=${base_name%.json}
  es_client "_xpack/watcher/watch/${name}?pretty=true" -X PUT --data-binary "@${i}"
done

function execute_jsonnet() {
  # MARQUEE_CUSTOMERS_TOP_LEVEL_DOMAINS should be comma-delimited
  jsonnet -J "${SCRIPT_DIR}" \
    --ext-str "marquee_customers_top_level_domains=${MARQUEE_CUSTOMERS_TOP_LEVEL_DOMAINS:-}" \
    "$@"
}

for i in "${SCRIPT_DIR}"/watches/*.jsonnet; do
  base_name=$(basename "$i")
  name=${base_name%.jsonnet}
  watch_json="$(execute_jsonnet "${i}"|jq -c '.')" # Compile jsonnet and compact with jq
  es_client "_xpack/watcher/watch/${name}?pretty=true"  -X PUT --data-binary "${watch_json}"
done

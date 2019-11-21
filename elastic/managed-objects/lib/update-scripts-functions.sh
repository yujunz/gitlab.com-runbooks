#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

function es_client() {
  url=$1
  shift
  curl --retry 3 --fail -H 'Content-Type: application/json' "${ES_URL}/${url}" "$@"
}

function execute_jsonnet() {
  # MARQUEE_CUSTOMERS_TOP_LEVEL_DOMAINS should be comma-delimited
  jsonnet -J "${SCRIPT_DIR}/../../lib" \
    --ext-str "marquee_customers_top_level_domains=${MARQUEE_CUSTOMERS_TOP_LEVEL_DOMAINS:-}" \
    "$@"
}

function ES5_upload_json() {
  for i in "${SCRIPT_DIR}"/*.json; do
    base_name=$(basename "$i")
    name=${base_name%.json}
    es_client "_xpack/watcher/watch/${name}?pretty=true" -X PUT --data-binary "@${i}"
  done
}

function ES5_watches_exec_jsonnet_and_upload_json() {
  for i in "${SCRIPT_DIR}"/*.jsonnet; do
    base_name=$(basename "$i")
    echo "$base_name"
    name=${base_name%.jsonnet}
    watch_json="$(execute_jsonnet "${i}" | jq -c '.')" # Compile jsonnet and compact with jq
    es_client "_xpack/watcher/watch/${name}?pretty=true" -X PUT --data-binary "${watch_json}"
  done
}

function ES7_watches_exec_jsonnet_and_upload_json() {
  for i in "${SCRIPT_DIR}"/*.jsonnet; do
    base_name=$(basename "$i")
    echo "$base_name"
    name=${base_name%.jsonnet}
    watch_json="$(execute_jsonnet "${i}" | jq -c '.')" # Compile jsonnet and compact with jq
    es_client "_watcher/watch/${name}" -X PUT --data-binary "${watch_json}"
  done
}

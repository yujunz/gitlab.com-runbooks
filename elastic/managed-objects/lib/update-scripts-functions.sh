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

function matches_exist() {
  [ -e "$1" ]
}

function get_json_and_jsonnet() {
  export array_file_path=/tmp/get_json_and_jsonnet.array
  declare -a json_array

  if matches_exist ./*.json; then
    for i in "${SCRIPT_DIR}"/*.json; do
      json_content=$(jq -c '.' "${i}")
      json_array+=("${json_content}")
    done
  fi

  if matches_exist ./*.jsonnet; then
    for i in "${SCRIPT_DIR}"/*.jsonnet; do
      json_content="$(execute_jsonnet "${i}" | jq -c '.')" # Compile jsonnet and compact with jq
      json_array+=("${json_content}")
    done
  fi

  if [ ${#json_array[@]} -eq 0 ]; then
    echo "No json or jsonnet files found."
    exit 1
  fi

  declare -p json_array >$array_file_path
}

# ES5
################################################################################

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

# ES7
################################################################################

function ES7_watches_exec_jsonnet_and_upload_json() {
  for i in "${SCRIPT_DIR}"/*.jsonnet; do
    base_name=$(basename "$i")
    echo "$base_name"
    name=${base_name%.jsonnet}
    watch_json="$(execute_jsonnet "${i}" | jq -c '.')" # Compile jsonnet and compact with jq
    es_client "_watcher/watch/${name}" -X PUT --data-binary "${watch_json}"
  done
}

function ES7_ILM_exec_jsonnet_and_upload_json() {
  for i in "${SCRIPT_DIR}"/*.jsonnet; do
    base_name=$(basename "$i")
    echo "$base_name"
    name=${base_name%.jsonnet}
    json="$(execute_jsonnet "${i}" | jq -c '.')" # Compile jsonnet and compact with jq
    es_client "_ilm/policy/${name}" -X PUT --data-binary "${json}"
  done
}

function ES7_index-template_exec_jsonnet_and_upload_json() {
  json=$(execute_jsonnet -e "local generic_index_template = import '$1'; generic_index_template.get('$2', '$3')")
  url="_template/gitlab_pubsub_$2_inf_$3_template"
  echo "${url}"
  es_client "${url}" -X PUT --data-binary "${json}"
}

function ES7_set_cluster_settings() {
  url="_cluster/settings"
  get_json_and_jsonnet
  source $array_file_path

  for json in "${json_array[@]}"; do
    es_client "${url}" -X PUT --data-binary "${json}"
  done
}

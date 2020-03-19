#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
export ES_URL=$ES_LOG_GPRD_URL
source "${SCRIPT_DIR}"/../../lib/update-scripts-functions.sh
source "${SCRIPT_DIR}"/../../indices/indices-array.sh
template_name='log_gprd_index_template.libsonnet'

env=gprd
# shellcheck disable=SC2154
for index in "${indices[@]}"; do
  ES7_index-template_exec_jsonnet_and_upload_json "$template_name" "$index" "$env"
done

ES7_put_json "_template/"

#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
export ES_URL=$ES_PROD_URL
source "${SCRIPT_DIR}"/../../lib/update-scripts-functions.sh

ES5_upload_json
ES5_watches_exec_jsonnet_and_upload_json

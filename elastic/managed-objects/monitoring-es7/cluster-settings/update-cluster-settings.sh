#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
export ES_URL=$ES_MONITORING_ES7_URL
source "${SCRIPT_DIR}"/../../lib/update-scripts-functions.sh

ES7_set_cluster_settings

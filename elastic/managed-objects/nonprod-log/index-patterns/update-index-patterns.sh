#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
export KIBANA_URL=$KIBANA_NONPROD_URL
source "${SCRIPT_DIR}"/../../lib/update-scripts-functions.sh

kibana_put_json "api/saved_objects/index-pattern/"

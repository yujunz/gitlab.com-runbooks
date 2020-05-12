#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
export ES_URL=$ES_SECURITY_DEV_URL
source "${SCRIPT_DIR}"/../../lib/update-scripts-functions.sh

ES7_put_json "_watcher/watch/"

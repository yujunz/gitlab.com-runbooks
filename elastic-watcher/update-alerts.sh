#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

for i in "${SCRIPT_DIR}"/watches/*.json; do
  base_name=$(basename "$i")
  name=${base_name%.json}
  curl --retry 3 --fail -X PUT "${ES_URL}/_xpack/watcher/watch/${name}?pretty=true" -H 'Content-Type: application/json'  --data-binary "@${i}"
done

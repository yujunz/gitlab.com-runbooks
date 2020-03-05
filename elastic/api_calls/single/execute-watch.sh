#!/usr/bin/env bash

set -eufo pipefail

watch_name=$1

curl -sSL -X POST -H 'Content-Type: application/json' "${ES7_URL_WITH_CREDS}/_watcher/watch/${watch_name}/_execute"

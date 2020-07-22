#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

fail() {
  echo "$@"
  exit 1
}

count=0
jsonnet --string "${SCRIPT_DIR}/routing-tests.jsonnet" --ext-str configFile="$1" | while read -r line; do
  count="$((count + 1))"
  sh -c "${line}" || fail "Failed test #${count}: ${line}"
done

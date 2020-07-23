#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "${SCRIPT_DIR}/.."

find . -name '*_test.jsonnet' -not -path "./vendor/*" | while read -r line; do
  echo "# ${line}"
  jsonnet -J vendor "$line"
done

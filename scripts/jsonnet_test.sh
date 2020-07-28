#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

find_tests() {
  find "$REPO_DIR" -name '*_test.jsonnet' -not -path "$REPO_DIR/vendor/*"
}

find_tests | while read -r line; do
  echo "# ${line}"
  jsonnet -J "$REPO_DIR/libsonnet" -J "$REPO_DIR/vendor" "$line"
done

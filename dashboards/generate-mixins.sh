#!/usr/bin/env bash
# vim: ai:ts=2:sw=2:expandtab

set -euo pipefail

IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "${SCRIPT_DIR}"

if [[ ! -d "vendor" ]]; then
  echo >&2 "vendor directory not found, running bundler.sh to install dependencies..."
  "${SCRIPT_DIR}/bundler.sh"
fi

# Install jsonnet dashboards
for mixin in *.mixin.libsonnet; do
  name="${mixin%.mixin.libsonnet}"
  rm -rf "$name"
  mkdir "$name"
  jsonnet -J vendor -m "$name" "$mixin"
done

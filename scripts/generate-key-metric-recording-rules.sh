#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

(
  echo "# WARNING. DO NOT EDIT THIS FILE BY HAND. USE ./scripts/generate-key-metric-recording-rules.sh TO GENERATE IT"
  echo "# YOUR CHANGES WILL BE OVERRIDDEN"
  jsonnet -S "${SCRIPT_DIR}/../metrics-catalog/recording-rules.jsonnet" | "${SCRIPT_DIR}/fix-prom-rules.rb"
) >"${SCRIPT_DIR}/../rules/autogenerated-key-metrics.yml"
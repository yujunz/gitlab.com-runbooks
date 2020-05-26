#!/usr/bin/env bash
set -euo pipefail

main() {
  while read -r line; do
    tool="$(echo "$line" | awk '{print $1}')"
    version="$(echo "$line" | awk '{print $2}')"
    "assert_version__$tool" "$version" || rc=$?
    if [ "${rc:-0}" -ne 0 ]; then
      echo "Expected ${tool} v${version}, got something else"
      return 1
    fi
  done <.tool-versions
}

assert_version__go-jsonnet() {
  jsonnet --version | grep -E "^Jsonnet commandline interpreter v${1}$"
}

main

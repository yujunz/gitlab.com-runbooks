#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATH="$(go env GOPATH)/bin:${PATH}"

if ! command -v jb >/dev/null; then
  echo >&2 "jsonnet-bundler not installed. Please run 'go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb'"
  exit 1
fi

cd "${SCRIPT_DIR}"
jb install

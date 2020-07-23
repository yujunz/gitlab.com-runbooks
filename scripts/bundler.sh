#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if hash go 2>/dev/null; then
  PATH="$(go env GOPATH)/bin:${PATH}"
fi

if ! command -v jb >/dev/null; then
  echo >&2 "jsonnet-bundler not installed. Please follow the instructions in https://gitlab.com/gitlab-com/runbooks/-/blob/master/README.md#required-tooling to install asdf and jsonnet-bundler."
  exit 1
fi

cd "${SCRIPT_DIR}/.."
jb install

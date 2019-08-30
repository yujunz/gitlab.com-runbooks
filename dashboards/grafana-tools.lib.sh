#!/usr/bin/env bash

function call_grafana_api() {
  local response

  response=$(curl -H 'Expect:' --http1.1 --compressed --silent --fail \
    -H "Authorization: Bearer $GRAFANA_API_TOKEN" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    "$@") || {
    echo >&2 "API call to $1 failed: $response: exit code $?"
    return 1
  }

  echo "$response"
}

function resolve_folder_id() {
  call_grafana_api "https://dashboards.gitlab.net/api/folders/$1" | jq '.id'
}

function prepare() {
  if [[ ! -d "vendor" ]]; then
    echo >&2 "vendor directory not found, running bundler.sh to install dependencies..."
    "bundler.sh"
  fi

  # Convert the service catalog yaml into a JSON file in a format thats consumable by jsonnet
  ruby -rjson -ryaml -e "puts YAML.load(ARGF.read).to_json" ../services/service-catalog.yml >service_catalog.json
}

function jsonnet_compile() {
  jsonnet -J . -J vendor "$@"
}

#!/usr/bin/env bash
# vim: ai:ts=2:sw=2:expandtab

set -euo pipefail

IFS=$'\n\t'
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${SCRIPT_DIR}"

usage() {
  cat <<-EOF
  Usage $0 [Dh]

  DESCRIPTION
    This script generates dashboards and uploads
    them to dashboards.gitlab.net

    GRAFANA_API_TOKEN must be set in the environment

    GRAFANA_FOLDER (optional): Override folder.
    Useful for testing.

  FLAGS
    -D  run in Dry-run
    -h  help

EOF
}

while getopts ":Dh" o; do
    case "${o}" in
        D)
            dry_run="true"
            ;;
        h)
            usage
            exit 0
            ;;
        *)
            ;;
    esac
done

shift $((OPTIND-1))

dry_run=${dry_run:-}

if [[ -z $dry_run && -z ${GRAFANA_API_TOKEN:-} ]]; then
    echo "You must set GRAFANA_API_TOKEN to use this script, or run in dry run mode"
    usage
    exit 1
fi

if [[ ! -d "vendor" ]]; then
  >&2 echo "vendor directory not found, running bundler.sh to install dependencies..."
  "${SCRIPT_DIR}/bundler.sh"
fi

# Convert the service catalog yaml into a JSON file in a format thats consumable by jsonnet
ruby -rjson -ryaml -e "puts YAML.load(ARGF.read).to_json"  ../services/service-catalog.yml > service_catalog.json

find_dashboards() {
  local find_opts
  find_opts=(
    "."
    # All *.jsonnet and *.json dashboards...
    "("
      "-name" '*.jsonnet'
    "-o"
      "-name" '*.json'
    ")"
    -not -name '.*'          # Exclude dot files
    -not -path "**/.*"       # Exclude dot dirs
    -not -path "./vendor/*"  # Exclude vendored files
    -mindepth 2              # Exclude files in the root folder
  )

  if [[ $# == 0 ]]; then
    find "${find_opts[@]}"
  else
    for var in "$@"
    do
      echo "${var}"
    done
  fi
}

call_grafana_api() {
  local response

  response=$(curl -H 'Expect:' --http1.1 --compressed --silent --fail \
    -H "Authorization: Bearer $GRAFANA_API_TOKEN" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    "$@") || {
      >&2 echo "API call to $1 failed: $response: exit code $?"
      return 1
    }

  echo "$response"
}

# Install jsonnet dashboards
find_dashboards "$@"|while read -r line; do
  relative=${line#"./"}
  folder=${GRAFANA_FOLDER:-$(dirname "$relative")}
  uid="${folder}-$(basename "$line"|sed -e 's/\..*//')"
  extension="${relative##*.}"

  if [[ "$extension" == "jsonnet" ]]; then
    dashboard=$(jsonnet -J . -J vendor "${line}")
  else
    dashboard=$(cat "${line}")
  fi

  # Note: create folders with `create-grafana-folder.sh` to configure the UID
  folderId=$(call_grafana_api "https://dashboards.gitlab.net/api/folders/${folder}" | jq '.id')

  # Generate the POST body
  body=$(echo "$dashboard"|jq -c --arg uid "$uid" --arg folderId "$folderId" '
  {
    dashboard: .,
    folderId: $folderId | tonumber,
    overwrite: true
  } * {
    dashboard: {
      uid: $uid
    }
  }')

  if [[ -n $dry_run ]]; then
    echo "Running in dry run mode, would create $line in folder $folder with uid $uid"
    continue
  fi

  # Use http1.1 and gzip compression to workaround unexplainable random errors that
  # occur when uploading some dashboards
  response=$(echo "$body"|call_grafana_api https://dashboards.gitlab.net/api/dashboards/db --data-binary @-)

  url=$(echo "${response}"| jq -r '.url')
  echo "Installed https://dashboards.gitlab.net${url}"
done

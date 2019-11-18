#!/usr/bin/env bash
# vim: ai:ts=2:sw=2:expandtab

set -euo pipefail

IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "${SCRIPT_DIR}"

source "grafana-tools.lib.sh"

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
    *) ;;

  esac
done

shift $((OPTIND - 1))

dry_run=${dry_run:-}

if [[ -z $dry_run && -z ${GRAFANA_API_TOKEN:-} ]]; then
  echo "You must set GRAFANA_API_TOKEN to use this script, or run in dry run mode"
  usage
  exit 1
fi

prepare

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
    -not -name '.*' # Exclude dot files
    -not -path "**/.*" # Exclude dot dirs
    -not -path "./vendor/*" # Exclude vendored files
    -mindepth 2 # Exclude files in the root folder
  )

  if [[ $# == 0 ]]; then
    find "${find_opts[@]}"
  else
    for var in "$@"; do
      echo "${var}"
    done
  fi
}

# Install jsonnet dashboards
find_dashboards "$@" | while read -r line; do
  relative=${line#"./"}
  folder=${GRAFANA_FOLDER:-$(dirname "$relative")}
  uid="${folder}-$(basename "$line" | sed -e 's/\..*//')"
  extension="${relative##*.}"

  if [[ "$extension" == "jsonnet" ]]; then
    dashboard=$(jsonnet_compile "${line}")
  else
    dashboard=$(cat "${line}")
  fi

  # Note: create folders with `create-grafana-folder.sh` to configure the UID
  folderId=$(resolve_folder_id "${folder}")

  uploader_identifier="${CI_JOB_URL:-$USER}"
  description="Uploaded by ${uploader_identifier} at $(date -u)"

  # Generate the POST body
  body=$(echo "$dashboard" | jq -c --arg uid "$uid" --arg folder "$folder" --arg folderId "$folderId" --arg description "$description" '
 {
    dashboard: .,
    folderId: $folderId | tonumber,
    overwrite: true
  } * {
    dashboard: {
      uid: $uid,
      title: "\($folder): \(.title)",
      tags: (["managed", $folder] + .tags),
      description: "\($description)"
    }
  }
')

  if (echo "${body}" | grep -E '%\(\w+\)' >/dev/null); then
    echo "$line output contains format markers. Did you forget to use %?"
    echo "${body}" | jq '.' | grep -E -B3 -A3 --color=always '%\(\w+\)'
    exit 1
  fi

  if (echo "${body}" | grep -E "' *\\+" >/dev/null); then
    echo "$line output contains format markers. Did you forget to use %?"
    echo "${body}" | jq '.' | grep -E -B3 -A3 --color=always "' *\\+"
    exit 1
  fi

  if [[ -n $dry_run ]]; then
    echo "Running in dry run mode, would create $line in folder $folder with uid $uid"
    continue
  fi

  # Use http1.1 and gzip compression to workaround unexplainable random errors that
  # occur when uploading some dashboards
  response=$(echo "$body" | call_grafana_api https://dashboards.gitlab.net/api/dashboards/db --data-binary @-)

  url=$(echo "${response}" | jq -r '.url')
  echo "Installed https://dashboards.gitlab.net${url}"
done

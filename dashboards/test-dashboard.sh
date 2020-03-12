#!/usr/bin/env bash
# vim: ai:ts=2:sw=2:expandtab

set -euo pipefail

IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "${SCRIPT_DIR}"

source "grafana-tools.lib.sh"

usage() {
  cat <<-EOF
  Usage $0 [Dh] path-to-file.dashboard.jsonnet

  DESCRIPTION
    This script generates dashboards and uploads
    them to the playground folder on dashboards.gitlab.net

    GRAFANA_API_TOKEN must be set in the environment

    Read dashboards/README.md for more details

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

if [[ $# != 1 ]]; then
  usage
  exit 0
fi

dry_run=${dry_run:-}

if [[ -z $dry_run && -z ${GRAFANA_API_TOKEN:-} ]]; then
  echo "You must set GRAFANA_API_TOKEN to use this script. Review the instructions in dashboards/README.md to details of how to obtain this token."
  exit 1
fi

prepare

dashboard_file=$1

relative=${dashboard_file#"./"}
extension="${relative##*.}"

if [[ "$extension" == "jsonnet" ]]; then
  dashboard=$(jsonnet_compile "${dashboard_file}")
else
  dashboard=$(cat "${dashboard_file}")
fi

if [[ -n $dry_run ]]; then
  echo "$dashboard"
  exit 0
fi

# Generate the POST body
body=$(echo "$dashboard" | jq -c '
{
  dashboard: .,
  expires: 86400
} * {
  dashboard: {
    editable: true,
    tags: ["playground"]
  }
}
')

# Use http1.1 and gzip compression to workaround unexplainable random errors that
# occur when uploading some dashboards
response=$(echo "$body" | call_grafana_api https://dashboards.gitlab.net/api/snapshots --data-binary @-)

url=$(echo "${response}" | jq -r '.url')
echo "Installed ${url}"

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
folder="playground-FOR-TESTING-ONLY"
dashboard_folder="$(dirname "$relative")"
base_dashboard_name="$(basename "$dashboard_file" | sed -e 's/\..*//')"
username="$USER"

uid="TESTING-$(dirname "$relative")-$USER-$(basename "$dashboard_file" | sed -e 's/\..*//')"
extension="${relative##*.}"

if [[ "$extension" == "jsonnet" ]]; then
  dashboard=$(jsonnet_compile "${dashboard_file}")
else
  dashboard=$(cat "${dashboard_file}")
fi

# Note: create folders with `create-grafana-folder.sh` to configure the UID
folderId=$(resolve_folder_id "${folder}")

# Generate the POST body
body=$(echo "$dashboard" | jq -c --arg uid "$uid" --arg folder "$folder" --arg folderId "$folderId" --arg titleFolderId "${dashboard_folder}" --arg baseDashboardName "${base_dashboard_name}" --arg username "${username}" '
{
  dashboard: .,
  folderId: $folderId | tonumber,
  overwrite: true
} * {
  dashboard: {
    uid: $uid,
    editable: true,
    title: "TESTING \($username) \($titleFolderId) \($baseDashboardName): \(.title)",
    tags: ["playground"]
  }
}
')

if [[ -n $dry_run ]]; then
  echo "Running in dry run mode, would create $dashboard_file in folder $folder with uid $uid"
  exit
fi

# Use http1.1 and gzip compression to workaround unexplainable random errors that
# occur when uploading some dashboards
response=$(echo "$body" | call_grafana_api https://dashboards.gitlab.net/api/dashboards/db --data-binary @-)

url=$(echo "${response}" | jq -r '.url')
echo "Installed https://dashboards.gitlab.net${url}"

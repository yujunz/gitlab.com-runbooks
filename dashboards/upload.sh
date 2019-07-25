#!/usr/bin/env bash

set -euo pipefail

IFS=$'\n\t'

usage() {
    cat <<-EOF
    Usage $0 [Dh]

    DESCRIPTION
        This script generates dashboards and uploads
        them to dashboards.gitlab.net

        GRAFANA_API_TOKEN must be set in the environment

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

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -d "${SCRIPT_DIR}/vendor" ]]; then
  >&2 echo "vendor directory not founder, running bundler.sh to install dependencies..."
  "${SCRIPT_DIR}/bundler.sh"
fi

find_dashboards() {
  if [[ $# == 0 ]]; then
    find "${SCRIPT_DIR}" '(' -name '*.dashboard.jsonnet' -o -name '*.dashboard.json' ')'
  else
    for var in "$@"
    do
      echo "${var}"
    done
  fi
}

# Install jsonnet dashboards
find_dashboards "$@"|while read -r line; do
  relative=${line#"$SCRIPT_DIR/"}
  folder=$(dirname "$relative")

  uid="${folder}-$(basename "$line"|sed -e 's/\..*//')"

  extension="${relative##*.}"
  if [[ "$extension" == "jsonnet" ]]; then
    dashboard=$(jsonnet -J "${SCRIPT_DIR}" -J "${SCRIPT_DIR}/vendor" -J "${SCRIPT_DIR}/vendor/grafonnet-lib" "${line}")
  else
    dashboard=$(cat "${line}")
  fi

  current_uid=$(echo "${dashboard}" | jq -r ".uid")
  if [[ -z ${current_uid} ]] || [[ ${current_uid}  == "null" ]]; then
    # If the dashboard doesn't have a uid, configure one
    dashboard=$(echo "${dashboard}" | jq ".uid = \"$uid\"")
  fi

  if [[ -n $dry_run ]]; then
      echo "Running in dry run mode, would create $line in folder $folder with uid $uid"
      continue
  fi

  # Note: create folders with `create-grafana-folder.sh` to configure the UID
  folderId=$(curl --silent --fail \
    -H "Authorization: Bearer $GRAFANA_API_TOKEN" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    "https://dashboards.gitlab.net/api/folders/${folder}" | jq '.id')


  response=$(curl --silent --fail \
    -H "Authorization: Bearer $GRAFANA_API_TOKEN" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    https://dashboards.gitlab.net/api/dashboards/db \
    -d"{
    \"dashboard\": ${dashboard},
    \"folderId\": ${folderId},
    \"overwrite\": true
  }") || {
    echo "Unable to install $relative"
    exit 1
  }

  url=$(echo "${response}"| jq -r '.url')
  echo "Installed https://dashboards.gitlab.net${url}"
done

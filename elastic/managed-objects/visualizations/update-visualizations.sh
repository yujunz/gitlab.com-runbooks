#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
source "${SCRIPT_DIR}"/../lib/update-scripts-functions.sh

# this script is not being used at the moment anyway, will review this when moving visualizations to this rep

#visualization=$(curl --fail "$ES_URL/.kibana/visualization/AWxNxiqsysVgSEDmrJd1")
#visualization_json=$(execute_jsonnet marquee-customers.jsonnet)
#
## Generate the POST body
#visualization_modified=$(echo "$visualization" | jq --arg visState "$(echo "$visualization_json" | jq -c '.visState')" --arg searchSourceJSON "$(echo "$visualization_json" | jq -c '.searchSourceJSON')" '
#  ._source * {
#    visState: $visState,
#    kibanaSavedObjectMeta: {
#      searchSourceJSON: $searchSourceJSON
#    }
#  }
#')
#
#echo "${visualization_modified}" | curl --fail -XPUT "$ES_URL/.kibana/visualization/AWxNxiqsysVgSEDmrJd1" -H 'Content-Type: application/json' -d @-
#
#echo ""
#
#echo 'https://log.gitlab.net/app/kibana#/visualize/edit/AWxNxiqsysVgSEDmrJd1?_g=()'

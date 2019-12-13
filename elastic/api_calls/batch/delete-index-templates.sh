#!/bin/bash

set -eufo pipefail
IFS=$'\t\n'
source ../../managed-objects/indices/indices-array.sh
env=$1

# shellcheck disable=SC2154
for index in "${indices[@]}"; do
  # delete a template
  curl -sSL -X DELETE "${ES7_URL_WITH_CREDS}/_template/gitlab_pubsub_${index}_inf_${env}_template"

done

#!/bin/bash

set -eufo pipefail
IFS=$'\t\n'

declare -a indices

indices=(
  api
  application
  camoproxy
  consul
  gitaly
  gke
  monitoring
  nginx
  pages
  postgres
  rails
  redis
  registry
  runner
  shell
  sidekiq
  system
  unicorn
  unstructured
  workhorse
)

env=$1

for index in "${indices[@]}"; do
  # delete a template
  curl -sSL -X DELETE "${ES7_URL_WITH_CREDS}/_template/gitlab_pubsub_${index}_inf_${env}_template"

done

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

curl_data_initialize() {
  cat <<EOF
{
    "aliases":
        {
            "pubsub-${index}-inf-${env}":
                {
                    "is_write_index": true
                }
        }

}
EOF
}

for index in "${indices[@]}"; do
  # initialize alias and create the first index
  curl -sSL -H 'Content-Type: application/json' -X PUT "${ES7_URL_WITH_CREDS}/pubsub-${index}-inf-${env}-000001" -d "$(curl_data_initialize)"

done

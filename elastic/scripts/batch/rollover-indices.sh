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

curl_data_close_index() {
  cat <<EOF
{
    "conditions": {
        "max_age": "1m"
    }
}
EOF
}

# if the index was rolled over without conditions, ILM would not know if it was closed so you would have to add to the index:
#{
#    "index": {
#        "lifecycle": {
#            "indexing_complete": "true"
#        }
#    }
#}

for index in "${indices[@]}"; do
  curl -sSL -H 'Content-Type: application/json' -X POST "${ES7_URL_WITH_CREDS}/pubsub-${index}-inf-${env}/_rollover" -d "$(curl_data_close_index)"
done

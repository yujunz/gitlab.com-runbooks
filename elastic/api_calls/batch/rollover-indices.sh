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

# if you're closing an index using the alias, ILM will not mark the index as complete, you'll have to run:
#{
#    "index": {
#        "lifecycle": {
#            "indexing_complete": "true"
#        }
#    }
#}
# more info here: https://github.com/elastic/elasticsearch/issues/44175

for index in "${indices[@]}"; do
  curl -sSL -H 'Content-Type: application/json' -X POST "${ES7_URL_WITH_CREDS}/pubsub-${index}-inf-${env}/_rollover" -d "$(curl_data_close_index)"
done

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

curl_data_template() {
  cat <<EOF
{
    "index_patterns": ["pubsub-${index}-inf-${env}-*"],
    "settings": {
            "index.lifecycle.name": "gitlab-infra-ilm-policy",
            "index.lifecycle.rollover_alias": "pubsub-${index}-inf-${env}",
            "index.mapping.total_fields.limit": "10000",
            "number_of_shards": 6
    },
    "mappings": {
        "properties": {
            "json": {
                "properties": {
                    "target_id": {
                        "type": "text",
                        "fields": {
                            "keyword": {
                                "type": "keyword",
                                "ignore_above": 256
                            }
                        }
                    }
                }
            }
        }
    }
}
EOF
}

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
  # we want to stick to the default 1 replica (which results in two copies of the data)
  # the reason for that is we don't know what data is missing when it goes missing, logs in ES are much more accessible than through BigQuery, we also rely on those logs to generate some metrics

  # create/update a template
  curl -sSL -H 'Content-Type: application/json' -X PUT "${ES7_URL_WITH_CREDS}/_template/gitlab_pubsub_${index}_inf_${env}_template" -d "$(curl_data_template)"

  # initialize alias and create the first index
  curl -sSL -H 'Content-Type: application/json' -X PUT "${ES7_URL_WITH_CREDS}/pubsub-${index}-inf-${env}-000001" -d "$(curl_data_initialize)"

done

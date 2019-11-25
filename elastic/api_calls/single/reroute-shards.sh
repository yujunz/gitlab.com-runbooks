#!/bin/bash

## Example of how to move (relocate) shard from one ES instance to another (ES 5.x) ##

curl_data_relocate() {
  cat <<EOF
{
    "commands" : [
        {
          "move" : {
                "index" : "logstash-2017.04.01", "shard" : 5,
                "from_node" : "log-es3", "to_node": "log-es4"
          }
        }
    ]
}
EOF
}

curl -sSL -H 'Content-Type: application/json' -X POST "${ES7_URL_WITH_CREDS}/_cluster/reroute" -d "$(curl_data_relocate)"

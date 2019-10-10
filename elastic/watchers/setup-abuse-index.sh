#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

curl -XPUT "${ES_URL}/gitaly-abuse-detection" -H 'Content-Type: application/json' -d'
{
    "mappings" : {
        "doc" : {
            "properties" : {
                "detected_at":  { "type":   "date" }
            }
        }
    }
}'

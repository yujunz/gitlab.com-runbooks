#!/bin/bash

set -eufo pipefail

curl -sSL "${ES7_URL_WITH_CREDS}/_cat/shards?v" | sort

# To see shards for specific index, you can use `curl http://<es_url>/_cat/shards/logstash-2017.04.01?v`

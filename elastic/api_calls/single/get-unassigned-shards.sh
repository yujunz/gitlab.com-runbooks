#!/bin/bash

set -eufo pipefail

curl -sSL "${ES7_URL_WITH_CREDS}/_cat/shards?h=index,shard,prirep,state,unassigned.reason" | grep UNASSIGNED

# To see shards for specific index, you can use `curl http://<es_url>/_cat/shards/logstash-2017.04.01`.
#
# Look out for shards which have both primary and replica missing - they are causing an unhealthy cluster
# and can't be recovered. Deleting the affected index is the easiest way to get it healthy again.

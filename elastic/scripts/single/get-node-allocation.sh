#!/bin/bash

set -eufo pipefail

# Show the current node allocation. This will tell you which nodes are available, how many shards each has, and how much disk space is being used/available:

curl -sSL "${ES7_URL_WITH_CREDS}/_cat/allocation?v"

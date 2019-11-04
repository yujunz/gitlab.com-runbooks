#!/bin/bash

set -eufo pipefail

index=$1

# this api will accept wildcards
# in newer versions of ES this can also be done using Kibana -> Index Management

curl -sSL -X DELETE "${ES7_URL_WITH_CREDS}/${index}"

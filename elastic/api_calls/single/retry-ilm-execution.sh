#!/bin/bash

set -eufo pipefail

index=$1

curl -sSL -X POST "${ES7_URL_WITH_CREDS}/${index}/_ilm/retry"

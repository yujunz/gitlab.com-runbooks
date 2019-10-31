#!/bin/bash

set -eufo pipefail

curl -sSL -X DELETE "${ES7_URL_WITH_CREDS}/_ilm/policy/gitlab-infra-ilm-policy"

#!/bin/bash

set -eufo pipefail

curl -sSL "${ES7_URL_WITH_CREDS}/_cat/thread_pool?v"

#!/bin/bash

set -eufo pipefail

if ! curl -s "${ELASTICSEARCH_URL}" > /dev/null; then
  >&2 echo "could not reach ELASTICSEARCH_URL"
  exit 1
fi

while [[ "$(curl -s "${ELASTICSEARCH_URL}/*/_ilm/explain?only_errors" | jq -r '.indices|length')" -gt 0 ]]; do
  # shellcheck disable=SC2016
  curl -s "${ELASTICSEARCH_URL}/*/_ilm/explain?only_errors" | jq -r '.indices|keys[]' | xargs -n1 bash -c 'echo $0; curl -s -XPOST "${ELASTICSEARCH_URL}/$0/_ilm/retry"; echo; sleep 10'
  echo
done

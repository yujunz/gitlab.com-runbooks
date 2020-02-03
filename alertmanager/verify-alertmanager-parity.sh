#!/bin/bash

set -u -o pipefail

upstream_yml='https://gitlab.com/gitlab-cookbooks/gitlab-alertmanager/raw/master/templates/default/alertmanager.yml.erb'
local_yml='alertmanager/alertmanager.yml.erb'

tmpfile=$(mktemp /tmp/alertmanager.yml.XXXXXXXX)
cleanup() {
  rm "${tmpfile}"
}
trap cleanup EXIT

if ! curl -fsL "${upstream_yml}" -o "${tmpfile}"; then
  echo "ERROR: Failed to fetch alertmanager config '${upstream_yml}'"
  exit 1
fi

if [[ $# -gt 0 && $1 == '-u' ]]; then
  echo "Updating local template."
  cp "${tmpfile}" "${local_yml}"
  exit 0
fi

# Attempt to match the configurations. If they do not match, fail
if ! cmp -s \
  <(awk 'NR>3' "${tmpfile}") \
  <(awk 'NR>3' "${local_yml}"); then

  echo "alertmanager.yml.erb files do not match between this repository and ${upstream_yml}"
  echo 'These files are intended to be kept in sync'

  diff -u \
    <(awk 'NR>3' "${tmpfile}") \
    <(awk 'NR>3' "${local_yml}")

  exit 1
fi

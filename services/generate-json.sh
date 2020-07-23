#!/usr/bin/env bash
#
# Description: Generate json from the service catalog, for ingestion in jsonnet
#

set -euo pipefail
IFS=$'\n\t'

cd "$(dirname "${BASH_SOURCE[0]}")"

generate() {
  source=$1
  target=$2

  if [[ ! -f "${target}" ]] || [[ ! -s "${target}" ]] || [[ "${source}" -nt "${target}" ]]; then
    # Update the service catalog
    ruby -rjson -ryaml -e "puts YAML.load(ARGF.read).to_json" "${source}" >"${target}"
  fi
}

generate "service-catalog.yml" "service_catalog.json"

# Next iteration will include stages.yml from www-gitlab-com
# generate "stages.yml" "stages.json"

# For now, we store stages.yml in this project,
# in future we may import this file dynamically
# curl --fail https://gitlab.com/gitlab-com/www-gitlab-com/-/raw/master/data/stages.yml -o stages.yml

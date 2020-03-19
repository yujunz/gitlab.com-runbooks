#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

find_docs() {
  find troubleshooting howto -type f -path "*$1*"
}

available_name() {
  local dest="$1"
  local ext
  local file
  ext="${dest##*.}"
  file="${dest%.*}"

  for i in "" "-1" "-2" "-3"; do
    if ! [[ -f "${file}${i}.${ext}" ]]; then
      echo "${file}${i}.${ext}"
      return
    fi
  done
}

git_mv() {
  local file=$1
  local service=$2
  local relative="${file#*/}"
  local dir
  local dest
  dir="$(dirname "docs/$service/$relative")"
  mkdir -p "$dir"

  dest=$(available_name "docs/$service/$relative")

  git mv "$file" "$dest"

  find . -type f \( -name "*.md" -o -name "*.y*ml" -o -name "*.*sonnet" \) -print0 | xargs -0 perl -p -i -e "s#$file#$dest#g"
  echo "$file:$dest"
}

move_all() {
  find_docs "$1" | while read -r line; do
    git_mv "$line" "$2"
  done
}

move_all 'gke' 'uncategorized'
move_all 'k8s' 'uncategorized'
move_all 'about-gitlab-com' 'uncategorized'
move_all 'runners' 'ci-runners'
move_all 'storage' 'gitaly'
move_all '-caching' 'web'
move_all 'gitlab-com-is-down' 'frontend'
move_all 'wale' 'patroni'
move_all 'walg' 'patroni'
move_all 'haproxy' 'frontend'
move_all 'high-error-rate' 'frontend'
move_all 'ssh-maxstartups-breach' 'frontend'
move_all 'monitor-gitlab-net' 'monitoring'
move_all 'clear_anonymous_sessions' 'redis'
move_all 'ssl_cert' 'frontend'
move_all 'user-auth' 'web'
move_all 'target-is-down' 'monitoring'
move_all 'silent-project-exports' 'sidekiq'
move_all 'pipeline' 'ci-runners'
move_all 'pg-ha' 'patroni'
move_all 'load-balancer' 'frontend'

for service in $(ruby -rjson -ryaml -e "puts YAML.load_file('services/service-catalog.yml').to_json" | jq -r '.services|sort_by(100 - (.name|utf8bytelength))[]|.name'); do
  move_all "$service" "$service"
done

move_all 'postgres' 'patroni'
move_all 'ci' 'ci-runners'
move_all 'prometheus' 'monitoring'
move_all 'thanos' 'monitoring'
move_all 'sentry' 'monitoring'
move_all 'queue' 'sidekiq'
git mv howto/externalvendors/cloudflare.md docs/waf/cloudflare-vendor.md
move_all 'cloudflare' 'waf'
move_all 'alerts' 'monitoring'
move_all 'alertmanager' 'monitoring'

move_all '' 'uncategorized'

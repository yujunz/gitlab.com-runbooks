#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

REPO_DIR=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.."
  pwd
)

usage() {
  cat <<-EOF
  Usage $0 -[Dh]

  DESCRIPTION
    This script will search for orphaned prometheusrules resources in the cluster
    that don't exist in the 'rules-k8s' directory and will issue a kubectl delete
    to remove them.

  FLAGS
    -D  run in Dry-run
    -h  help

EOF
}

while getopts ":Dh" o; do
  case "${o}" in
    D)
      dry_run="true"
      ;;
    h)
      usage
      exit 0
      ;;
    *) ;;

  esac
done

shift $((OPTIND - 1))
dry_run=${dry_run:-}

KUBE_TYPE=prometheusrules
KUBE_NAMESPACE=monitoring

# Generate a list of resources in the cluster that don't exist in the rules-k8s directory
# And tell kubectl to delete them
comm -13 \
  <(ruby -ryaml -e 'ARGV.each { |f| puts YAML.load_file(f)["metadata"]["name"] }' "${REPO_DIR}/rules-k8s/"*.yml | sort) \
  <(kubectl get "${KUBE_TYPE}" -n "${KUBE_NAMESPACE}" -o=custom-columns=NAME:.metadata.name --no-headers | sort) |
  (
    if [[ -n $dry_run ]]; then
      xargs --no-run-if-empty echo kubectl delete -n "${KUBE_NAMESPACE}" "${KUBE_TYPE}"
    else
      xargs --no-run-if-empty kubectl delete -n "${KUBE_NAMESPACE}" "${KUBE_TYPE}"
    fi
  )

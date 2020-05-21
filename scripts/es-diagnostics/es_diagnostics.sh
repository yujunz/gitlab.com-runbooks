#!/usr/bin/env bash

# Requires the following env vars:
# CLUSTER_URL
# CLUSTER_CREDS
# GOOGLE_APPLICATION_CREDENTIALS
# BUCKET_NAME

set -euo pipefail

# additional settings for the hot threads api
THREADS_INTERVAL="${THREADS_INTERVAL:-500ms}"
THREADS_SNAPSHOTS="${THREADS_SNAPSHOTS:-10}"
THREADS_THREADS="${THREADS_THREADS:-3}"
THREADS_TYPE="${THREADS_TYPE:-cpu}"

CONT_HEADER="Content-Type: application/json"
DIR_NAME="es_threads_tasks_dump_$(date +%Y-%m-%d_%H:%M:%S -u)"
SCRIPT_DIR="$(dirname "$0")"

if [[ -z ${CLUSTER_URL+x} ]] || [[ -z ${CLUSTER_CREDS+x} ]] || [[ -z ${GOOGLE_APPLICATION_CREDENTIALS+x} ]] || [[ -z ${BUCKET_NAME+x} ]]; then
  echo "Required env vars missing. Please see the script for more details."
  exit 1
fi

if [[ ! -e ${GOOGLE_APPLICATION_CREDENTIALS} ]]; then
  echo "Service account key file is missing!"
  exit 1
fi

mkdir "${DIR_NAME}"
curl -f -H "${CONT_HEADER}" -u "${CLUSTER_CREDS}" "${CLUSTER_URL}_cat/indices?v&pri&s=index&h=index,pri,rep,docs.count,docs.deleted,pri.store.size&bytes=gb" >"${DIR_NAME}/cat_indices"
curl -f -H "${CONT_HEADER}" -u "${CLUSTER_CREDS}" "${CLUSTER_URL}_cat/thread_pool?v" >"${DIR_NAME}/cat_thread_pool"
curl -f -H "${CONT_HEADER}" -u "${CLUSTER_CREDS}" "${CLUSTER_URL}_cluster/health" >"${DIR_NAME}/cluster_health.json"
curl -f -H "${CONT_HEADER}" -u "${CLUSTER_CREDS}" "${CLUSTER_URL}_cluster/pending_tasks" >"${DIR_NAME}/cluster_pending_tasks.json"
curl -f -H "${CONT_HEADER}" -u "${CLUSTER_CREDS}" "${CLUSTER_URL}_tasks?detailed=true" >"${DIR_NAME}/tasks.json"
curl -f -H "${CONT_HEADER}" -u "${CLUSTER_CREDS}" "${CLUSTER_URL}_nodes/hot_threads?interval=${THREADS_INTERVAL}&snapshots=${THREADS_SNAPSHOTS}&threads=${THREADS_THREADS}&type=${THREADS_TYPE}" >"${DIR_NAME}/nodes_hot_threads"

"${SCRIPT_DIR}/collapse_hot_threads.rb" <"${DIR_NAME}/nodes_hot_threads" | "${SCRIPT_DIR}/flamegraph.pl" >"${DIR_NAME}/hot_threads.svg"
"${SCRIPT_DIR}/collapse_hot_threads.rb" --node <"${DIR_NAME}/nodes_hot_threads" | "${SCRIPT_DIR}/flamegraph.pl" >"${DIR_NAME}/hot_threads_node.svg"
"${SCRIPT_DIR}/collapse_hot_threads.rb" --index <"${DIR_NAME}/nodes_hot_threads" | "${SCRIPT_DIR}/flamegraph.pl" >"${DIR_NAME}/hot_threads_index.svg"

gcloud auth activate-service-account --key-file="${GOOGLE_APPLICATION_CREDENTIALS}"
gsutil -m cp -R "${DIR_NAME}" "gs://${BUCKET_NAME}/"

rm -rf "${DIR_NAME}"

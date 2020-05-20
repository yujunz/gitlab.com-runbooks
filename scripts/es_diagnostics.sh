#!/usr/bin/env bash

# Requires the following env vars:
# CLUSTER_URL
# CLUSTER_CREDS
# GOOGLE_APPLICATION_CREDENTIALS
# BUCKET_NAME

set -euo pipefail

CONT_HEADER="Content-Type: application/json"
AUTH_HEADER="Authorization: Basic ${CLUSTER_CREDS}"
DIR_NAME="es_threads_tasks_dump_$(date +%Y-%m-%d_%H:%M:%S -u)"

if [[ -z ${CLUSTER_URL+x} ]] || [[ -z ${CLUSTER_CREDS+x} ]] || [[ -z ${GOOGLE_APPLICATION_CREDENTIALS+x} ]] || [[ -z ${BUCKET_NAME+x} ]]; then
  echo "Required env vars missing. Please see the script for more details."
  exit 1
fi

if [[ ! -e ${GOOGLE_APPLICATION_CREDENTIALS} ]]; then
  echo "Service account key file is missing!"
  exit 1
fi

mkdir "${DIR_NAME}"
(
  cd "${DIR_NAME}"
  curl -f -H "${CONT_HEADER}" -H "${AUTH_HEADER}" "${CLUSTER_URL}_cat/indices?v&pri&s=index&h=index,pri,rep,docs.count,docs.deleted,pri.store.size&bytes=gb" >cat_indices
  curl -f -H "${CONT_HEADER}" -H "${AUTH_HEADER}" "${CLUSTER_URL}_cat/thread_pool?v" >cat_thread_pool
  curl -f -H "${CONT_HEADER}" -H "${AUTH_HEADER}" "${CLUSTER_URL}_cluster/health" >cluster_health.json
  curl -f -H "${CONT_HEADER}" -H "${AUTH_HEADER}" "${CLUSTER_URL}_cluster/pending_tasks" >cluster_pending_tasks.json
  curl -f -H "${CONT_HEADER}" -H "${AUTH_HEADER}" "${CLUSTER_URL}_tasks?detailed=true" >tasks.json
  curl -f -H "${CONT_HEADER}" -H "${AUTH_HEADER}" "${CLUSTER_URL}_nodes/hot_threads" >nodes_hot_threads
)

gsutil -m cp -R "${DIR_NAME}" "gs://${BUCKET_NAME}/"

rm -rf "${DIR_NAME}"

#!/usr/bin/env bash

set -eux

declare -r project='gitlab-ops'
declare -r bucket='gitlab-configs'
declare -r kms_keyring='gitlab-shared-configs'
declare -r kms_key='config'
declare -r am_file='alertmanager.yml'

gcloud auth activate-service-account --key-file "${SERVICE_KEY}"
gcloud config set project "${project}"

gcloud --project "${project}" kms encrypt --location=global --keyring="${kms_keyring}" --key="${kms_key}" --ciphertext-file="${am_file}.enc" --plaintext-file="${am_file}"
gsutil cp "${am_file}.enc" "gs://${bucket}/${am_file}.enc"

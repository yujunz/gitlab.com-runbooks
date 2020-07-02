#!/usr/bin/env bash

set -eux

declare -r project='gitlab-ops'
declare -r bucket='gitlab-configs'
declare -r kms_keyring='gitlab-shared-configs'
declare -r kms_key='config'

gcloud auth activate-service-account --key-file "${SERVICE_KEY}"
gcloud config set project "${project}"

for file in *.yml *.yaml; do
  gcloud --project "${project}" kms encrypt \
    --location=global \
    --keyring="${kms_keyring}" \
    --key="${kms_key}" --ciphertext-file="${file}.enc" \
    --plaintext-file="${file}"
  gsutil cp "${file}.enc" "gs://${bucket}/${file}.enc"
done

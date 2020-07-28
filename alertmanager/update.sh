#!/usr/bin/env bash

set -eux

declare -r project='gitlab-ops'
declare -r bucket='gitlab-configs'
declare -r kms_keyring='gitlab-shared-configs'
declare -r kms_key='config'

gcloud auth activate-service-account --key-file "${SERVICE_KEY}"
gcloud config set project "${project}"
gcloud container clusters get-credentials "${CLUSTER}" --region "${REGION}"

for file in alertmanager.yml k8s_alertmanager.yaml; do
  gcloud --project "${project}" kms encrypt \
    --location=global \
    --keyring="${kms_keyring}" \
    --key="${kms_key}" --ciphertext-file="${file}.enc" \
    --plaintext-file="${file}"
  gsutil cp "${file}.enc" "gs://${bucket}/${file}.enc"
done

kubectl apply --filename ./k8s_alertmanager_secret.yaml

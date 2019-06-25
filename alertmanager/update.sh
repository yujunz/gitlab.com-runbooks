#!/usr/bin/env bash

set -eux

declare -r project='gitlab-ops'
declare -r bucket='gitlab-configs'
declare -r kms_keyring='gitlab-shared-configs'
declare -r kms_key='config'
declare -r chef_file='chef_alertmanager.yml'
declare -r k8s_file='k8s_alertmanager.yaml'

gcloud auth activate-service-account --key-file "${SERVICE_KEY}"
gcloud config set project "${project}"

declare -r files=("${chef_file}" "${k8s_file}")

for file in "${files[@]}"
do
  gcloud --project "${project}" kms encrypt --location=global --keyring="${kms_keyring}" --key="${kms_key}" --ciphertext-file="${file}".enc --plaintext-file="${file}"
  gsutil cp "${file}".enc gs://"${bucket}"/"${file}".enc
done

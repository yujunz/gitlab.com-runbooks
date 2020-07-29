#!/usr/bin/env bash

set -eux

declare -r project='gitlab-ops'
declare -r bucket='gitlab-configs'
declare -r kms_keyring='gitlab-shared-configs'
declare -r kms_key='config'

gcloud auth activate-service-account --key-file "${SERVICE_KEY}"
gcloud config set project "${project}"

# TODO make the branch below the only code path this script follows after
# https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/merge_requests/136
# is successfully rolled out, and
# https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10546 is
# complete. After this, no-one will be using the GCS+GKMS alertmanager config
# files that were consumed by chef and helm.
if [[ "${CI_ENVIRONMENT_NAME:-}" == "ops" ]]; then
  gcloud container clusters get-credentials "${CLUSTER}" --region "${REGION}"
  kubectl apply --filename ./k8s_alertmanager_secret.yaml
  exit 0
fi

for file in alertmanager.yml k8s_alertmanager.yaml; do
  gcloud --project "${project}" kms encrypt \
    --location=global \
    --keyring="${kms_keyring}" \
    --key="${kms_key}" --ciphertext-file="${file}.enc" \
    --plaintext-file="${file}"
  gsutil cp "${file}.enc" "gs://${bucket}/${file}.enc"
done

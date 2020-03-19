# Working with Google Cloud secrets

# Prechecks

- Install and configure the [Google Cloud SDK](https://cloud.google.com/sdk/docs/)
- [Set up access for gcloud CLI](gcloud-cli.md)
- Ensure you have access to the relevant Google Cloud Platform project
- Ensure you have permissions for Storage, KMS and IAM on the relevant Google Cloud Platform project

# Downloading and decrypting a secrets file

You'll need to know the bucket name and the path to the secret file. For secrets
handled by the [gitlab-vault cookbook](https://gitlab.com/gitlab-cookbooks/gitlab-vault),
if you have the following in a Chef node:

```json
"secrets": {
    "backend": "gkms",
        "path": {
        "path": "path/to/secrets",
        "item": "item.enc"
    },
    "key": {
        "ring": "my-keyring",
        "key": "my-key",
        "location": "global"
    }
}
```

You will also need to know the project ID:

* Staging: gitlab-staging-1
* Production: gitlab-production

Run the following:

```bash
gsutil cp gs://path/to/secrets/item.enc - | gcloud kms decrypt --project=project-id-here --keyring=my-keyring --key=my-key --location=global --ciphertext-file=- --plaintext-file=/path/to/plaintext
```

After that on `/path/to/plaintext` you'll have a decrypted copy of the file.

# Encrypting and uploading a secrets file

```bash
gcloud kms encrypt --project=project-id-here --keyring=my-keyring --key=my-key --location=global --ciphertext-file=- --plaintext-file=/path/to/plaintext | gsutil cp - gs://path/to/secrets/item.enc
```

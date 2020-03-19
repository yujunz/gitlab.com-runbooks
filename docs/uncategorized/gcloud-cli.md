# Getting setup with Google gcloud CLI

## Install

- Install the [Google Cloud SDK](https://cloud.google.com/sdk/docs/)
  - Using Homebrew `brew cask install google-cloud-sdk`

## Authenticate

```
gcloud auth login
gcloud config set project gitlab-production
gcloud auth application-default login
```

This will create a .json file in `$HOME/.config/gcloud/application_default_credentials.json`
which will provide default credentials to applications using the Google Cloud SDK

## Links:

- The [Google Cloud Platform Dashboard](https://console.cloud.google.com/home)
- [gcloud auth application-default login](https://cloud.google.com/sdk/gcloud/reference/auth/application-default/login)

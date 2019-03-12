## Summary

This directory contains the kubernetes configuration for the GKE runner cluster
that is created by Terraform run for the projects that config runners on GKE.

Currently this is:
* gitlab-ops
* gitlab-pre

But these instructions can be used to configure gitlab-runner on any GKE
cluster.

Before you start, set the following two environment variables.
For example for the preprod environment

```
export GITLAB_ENDPOINT=pre.gitlab.com
export GITLAB_PROJECT=gitlab-pre
```

Then run `DOLLAR='$' envsubst < README.md` to generate the configure cluster instruction
below. If you do not have `envsubst` installed run
```
brew install gettext
```


## Configuring the cluster


1. Install gitlab-runner on your workstation https://docs.gitlab.com/runner/install/osx.html
1. Generate a cicd token. Use  `https://$GITLAB_ENDPOINT` as the endpoint for `/usr/local/bin/gitlab-runner register`
  1. Use `$GITLAB_ENDPOINT` as the coordinator URL
  1. Get the registration CI token on `https://$GITLAB_ENDPOINT/admin/runners`
  1. Use `kubernetes` as the executor
1. Generate the kubectl configuration for the cluster by running the `connect to
   cluster` option in the console UI, for example in PreProd it looks like this:
   `gcloud container clusters get-credentials pre-gke-runner --zone us-east1-b --project $GITLAB_PROJECT`
1. Retrieve the token from the [admin runner page on $GITLAB_ENDPOINT](https://$GITLAB_ENDPOINT/admin/runners)
   and set it `export RUNNER_TOKEN=<token value>` It will be substituted in the configmap
   when the configuration is applied.
1. Apply the configuration `for f in $(/bin/ls *.yml); do envsubst < "${DOLLAR}f" | kubectl apply -f -; done`
1. Confirm that the runner is able to contact pre on the [runner admin page](https://$GITLAB_ENDPOINT/admin/runners)
1. If things aren't working properly see the status of the pods by running `kubectl get all -n gitlab`

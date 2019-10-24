# Debug failed chef provisioning

## Background

We provision GCP machines with terraform and Chef. Most machines are provisioned
using one of several terraform modules. For example, one of these modules would
[declare a bootstrap module instance](https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/google/generic-stor/blob/2127ddf7d5c153970b8ba5780f1c72c6aa9873f8/main.tf#L1),
which
[copies a bootstrap script to the new instance](https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/google/bootstrap/blob/582d1377032c4f6d524b1e92d1fd99099acf3055/main.tf#L9),
which is
[configured to run on boot](https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/google/generic-stor/blob/42c43a363bee441416ba4e3a1459c99b97e7c13e/instance.tf#L139).

This bootstrap script is responsible for enrolling the machine with our Chef
server, using an initial runlist and environment
[obtained from GCE instance metadata](https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/google/generic-stor/blob/42c43a363bee441416ba4e3a1459c99b97e7c13e/instance.tf#L18-36.)

Most of our chef roles depend on some base role that adds ssh users and
authorized_keys using [a
cookbook](https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/google/generic-stor/blob/42c43a363bee441416ba4e3a1459c99b97e7c13e/instance.tf#L18-36).
As a base role dependency, this cookbook runs early in the provisioning process.
If a later cookbook fails during the initial chef bootstrap, we usually ssh in
to debug the problem.

If you are iterating on early-run recipes, or the bootstrap script itself, it's
possible for the bootstrapping run to not get to the point at which you can ssh
into the machine. That is the problem this runbook is here for.

## Debugging

### Tail the serial port output

The startup script logs, which include the chef-client logs as it is run in the
foreground, are visible on the serial console output. In GCP this can be
accessed using gcloud, e.g.:

```
gcloud --project=gitlab-production compute instances tail-serial-port-output \
  sidekiq-besteffort-06-sv-gprd --zone=us-east1-b
```

### ssh to the instance

1. Using the GCP web console, add a public IP to the instance if it doesn't
   already have one.
1. Temorarily add an ssh key for your GCP user and shh in: `gcloud compute
   --project "gitlab-staging-1" ssh --zone "us-east1-d"
   gke-gstg-gitlab-gke-node-pool-2019092-7eaabcbf-1zl6 --tunnel-through-iap`.
   The `--tunnel-through-iap` is there in case the instance has no public IP.
1. Remove the public IP (if created).

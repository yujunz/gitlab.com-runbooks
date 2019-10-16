# Summary

This document summarizes operating the Kubernetes clusters
for GitLab.com. For managing individual services see the
`k8s-<name>-operations.md` HOWTOs.

_Note: Before starting an oncall shift, be usre you follow these setup
instructions_

## Console Server setup for the oncall

Configuration changes are handled through GitLab CI so most of what we do does
not require interacting with the cluster directly. Management of our staging and production clusters is
limited to our `console` instances.  As an oncall SRE, you should also setup
your user on the console node to interact with the Kubernetes API.

:warning: Do not perform any of these actions using the `root` user, nor `sudo` :warning:

Perform the below work on the appropriate `console` server

* `gstg` - `console-01-sv-gstg.c.gitlab-staging-1.internal`
* `gprd` - `console-01-sv-gprd.c.gitlab-production.internal`

- [ ] Authenticate with `gcloud`

```
gcloud auth login
```

> If you see warnings about permissions issues related to `~/.config/gcloud/*`
> check the permissions of this directory.  Simply change it to your user if
> necessary: `sudo chown -R $(whoami) ~/.config`

You'll be prompted to accept that you are using the `gcloud` on a shared
computer and presented with a URL to continue logging in with, after which
you'll be provided a code to pass into the command line to complete the
process.  By default, `gcloud` will configure your user within the same project
configuration for which that `console` server resides.

- [ ] Get the credentials for production and staging:

```
gcloud container clusters get-credentials gstg-gitlab-gke --region us-east1 --project gitlab-staging-1
gcloud container clusters get-credentials gprd-gitlab-gke --region us-east1 --project gitlab-production
```

This should add the appropriate context for `kubectl`, so the following should
work and display the nodes running on the cluster:

- [ ] `kubectl get nodes`

**:warning: It is not the intention of the console servers to utilize the `k-ctl`
script or any of the components necessary.  These servers provide the sole means
of troubleshooting a misbehaving cluster or application.  Any changes that
involve the use of `helm` or `k-ctl` MUST be done via the repo and CI/CD.
:warning:**

## Workstation setup

- [ ] Clone `git@gitlab.com:gitlab-com/gl-infra/k8s-workloads/gitlab-com`
- [ ] `cd` into the cloned repo
- [ ] execute `./bin/k-ctl -t`

This will validate you have all required components installed necessary to
interact with this repo.  Follow the links provided to complete the necessary
installs of missing components.  Note that if you have a preferred method of
installing this tools, it's perfectly fine to utilize your preferred method.
`k-ctl` doesn't care how items are installed, only that they are accessible in
your `$PATH`.

- [ ] Get the credentials for the pre-prod cluster:

```
gcloud container clusters get-credentials pre-gitlab-gke --region us-east1 --project gitlab-pre
```

- [ ] Validate k-ctl works as desired

```
./bin/k-ctl -e pre list
```

You should see a successful output of the helm objects as well as custom
Kubernetes objects managed by the `gitlab-com` repository.


- [ ] Familiarize yourself with the deployment pipeline for Container Registry, see an
  [example that deploys a change from non-production to production](https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/gitlab-com/pipelines/75089).

- [ ] Ensure you can SSH to a production node

```
# Query the name of one of the GKE nodes
gcloud compute instances list --project "gitlab-production" | grep ^gke

# Initiate an SSH connection to one of the production nodes, this requires a fairly recent version of gsuite
gcloud compute --project "gitlab-production" ssh --zone us-east1-b gke-gprd-gitlab-gke-node-pool-0-ec8ba4d2-q1j9 --tunnel-through-iap
```

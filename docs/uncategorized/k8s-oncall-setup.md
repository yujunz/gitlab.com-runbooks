# Summary

_Note: Before starting an on-call shift, be sure you follow these setup
instructions_

## Install helm and plugins locally

There are two projects for deploying helm to the pre/gtsg/gprd Kubernetes clusters:

* https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com
* https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles

In both of these projects there is a `.tool-versions` file that should be used with `asdf` to install the correct versions of helm and helmfile.

- [ ] Install helm and helmfile
- [ ] Install helm plugins by running the script https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/common/-/blob/master/bin/install-helm-plugins.sh

## Kubernetes API Access

We use private GKE clusters, with the control plane only accessible from within the cluster's VPC.
There are 2 that we currently use for access: console hosts, and ssh tunnels.

### Console Server setup for the oncall

Configuration changes are handled through GitLab CI so most of what we do does not require interacting with the cluster directly.
Management of our staging and production clusters is limited to our `console` instances.
As an oncall SRE, you should also setup your user on the console node to interact with the Kubernetes API.

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

Running `gcloud auth revoke` (among other things) removes the kubernetes credentials (it wipes them from the `~/.kube/config` file).

**:warning: It is not the intention of the console servers to utilize the `k-ctl`
script or any of the components necessary.  These servers provide the sole means
of troubleshooting a misbehaving cluster or application.  Any changes that
involve the use of `helm` or `k-ctl` MUST be done via the repo and CI/CD.
:warning:**

### Accessing the zonal clusters

The zonal clusters must be accessed through the console servers, but they are best accessed using an ssh tunnel. We will access the clusters this way until this issues in the [access epic](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/337) are completed.

[`sshuttle`](https://github.com/sshuttle/sshuttle) automates the process of setting up an ssh tunnel _and_ modifying your local route table to forward traffic to the configured CIDR.


- [ ] Get the credentials for the zonal clusters

```
gcloud container clusters get-credentials gstg-us-east1-b --region us-east1-b --project gitlab-staging-1
gcloud container clusters get-credentials gstg-us-east1-c --region us-east1-c --project gitlab-staging-1
gcloud container clusters get-credentials gstg-us-east1-d --region us-east1-d --project gitlab-staging-1
gcloud container clusters get-credentials gprd-us-east1-b --region us-east1-b --project gitlab-production
gcloud container clusters get-credentials gprd-us-east1-c --region us-east1-c --project gitlab-production
gcloud container clusters get-credentials gprd-us-east1-d --region us-east1-d --project gitlab-production
```

- [ ] Create sshuttle wrappers for initiating tunneled connections

```
# kubectx gke_gitlab-production_us-east1-b_gprd-us-east1-b
sshuttle -r console-01-sv-gprd.c.gitlab-production.internal '35.185.25.234/32'

# kubectx gke_gitlab-production_us-east1-c_gprd-us-east1-c
sshuttle -r console-01-sv-gprd.c.gitlab-production.internal '34.75.253.130/32'

# kubectx gke_gitlab-production_us-east1-d_gprd-us-east1-d
sshuttle -r console-01-sv-gprd.c.gitlab-production.internal '34.73.149.139/32'

# kubectx gke_gitlab-staging-1_us-east1-b_gstg-us-east1-b
sshuttle -r console-01-sv-gstg.c.gitlab-staging-1.internal '34.74.13.203/32'

# kubectx gke_gitlab-staging-1_us-east1-c_gstg-us-east1-c
sshuttle -r console-01-sv-gstg.c.gitlab-staging-1.internal '35.237.127.243/32'

# kubectx gke_gitlab-staging-1_us-east1-d_gstg-us-east1-d
sshuttle -r console-01-sv-gstg.c.gitlab-staging-1.internal '35.229.107.91/32'

# kubectx gke_gitlab-staging-1_us-east1_gstg-gitlab-gke
sshuttle -r console-01-sv-gstg.c.gitlab-staging-1.internal '34.73.144.43/32'
```

- [ ] Ensure you can list pods in one of the regions

```
sshuttle -r console-01-sv-gstg.c.gitlab-staging-1.internal '34.73.144.43/32'
kubectl get pods -n gitlab
```

**Note**: Optionally you rename your context to something less unwiedly: `kubectl config rename-context gke_gitlab-production_us-east1_gprd-gitlab-gke gprd`

### SSH Access to pods

* [ ] Initiate an SSH connection to one of the production nodes, this requires a fairly recent version of gsuite

```
kubectl get pods -o wide
gcloud compute --project "gitlab-production" ssh <node name>
```

From the node you can list containers, and ssh into a pod as root:

```
docker exec -u root -it <container> /bin/bash
```

* [ ] Use toolbox to run strace on process running in one of the GitLab containers

```
gcloud compute --project "gitlab-production" ssh <node name>
toolbox
```
## Workstation setup for k-ctl

* [ ] Get the credentials for the pre-prod cluster:

```
gcloud container clusters get-credentials pre-gitlab-gke --region us-east1 --project gitlab-pre
```

* [ ] Setup local environment for `k-ctl`

These steps walk through running `k-ctl` against the preprod cluster but can also be used to connect to any of the staging or production clusters using sshuttle above.
It is probably very unlikely you will need to make a configuration change to the clusters outside of CI, follow these instructions for the rare case this is necessary.
`k-ctl` is a shell wrapper used by the [k8s-workloads/gitlab-com](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com) over `helmfile`.

```
git clone git@gitlab.com:gitlab-com/gl-infra/k8s-workloads/gitlab-com
cd gitlab-com
export CLUSTER=pre-gitlab-gke
export REGION=us-east1
./bin/k-ctl -e pre list
```

You should see a successful output of the helm objects as well as custom Kubernetes objects managed by the `gitlab-com` repository.

* [ ] Make a change to the preprod configuration and execute a dry-run
```
vi releases/gitlab/values/pre.yaml.gotmpl
# Make a change
./bin/k-ctl -e pre -D apply
```

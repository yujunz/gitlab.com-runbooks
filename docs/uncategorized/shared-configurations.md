# Shared Configurations

In this document we'll discuss the topic of shared secrets and shared
configuration items that tie our Kubernetes and Chef infrastructure together.

## Single Source of Truth (SSOT)

Due to the nature of migrating GitLab from our historical VM instance based
infrastructure managed by Chef, into Kubernetes utilizing our GitLab Helm Chart,
there needs to exist a method of pulling data that is the same between them such
that a change in one infrastructure is not lost or forgotten to be changed in
another.  For this, we've evaluated where the majority of our infrastructure
lives and the ease of populating configurations.  Currently, we are relying on
our [`chef-repo`] as a SSOT.  This means for any shared configurations that are not
secret, we'll reach out to our Ops GitLab instance to retrieve the desired data.
For secrets that are shared, we'll utilize our existing [`GKMS Vaults`].

To see the work responsible for this implementation can be viewed in the
[Infrastructure Epic 167](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/167)

## How Items are Shared

As configurations or secrets are added to the existing systems, whether that be
inside of [`chef-repo`] or inside of a [`GKMS Vault`], this will populate our servers as
expected and governed by the chef cookbooks.  For infrastructure living in
Kubernetes, a custom helm chart has been created that makes the appropriate API
calls for the GitLab Ops Instance, or shelling out to the `gcloud` CLI as
necessary to pull this data.

### [`k8s-workloads/gitlab-com`]

#### Secrets

This repo contains a custom helm chart located here:
https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab-secrets.yaml
That contains all shared secrets.  This custom helm chart currently utilizes
shell commands, `gcloud`, `gsutil`, and `jq` to pull the necessary values
required out of our [`GKMS Vault`].  A few details about this can be found in
the
[README}(https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/tree/master#gitlab-secrets)
of [`k8s-workloads/gitlab-com`].

#### Configurations (Non-Secrets)

This repo utilizes `helmfile` to help populate our configuration values that are
shared between [`chef-repo`].  The common location to find this data is in a
specific file
[`values-from-external-sources.yaml.gotmpl`](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/values/gitlab/values-from-external-sources.yaml.gotmpl).
When [`helmfile`] generates the values for our templates, it does so by shelling
out via `curl`, `gsutil`, `gcloud`, and `jq` as necessary.

## Rolling out Configuration/Secret Changes

Clearly defined steps are not possible as it greatly depends on the value that
is being updated.  Utilize the below steps as a guideline only, leverage the
staging environment as much as possible for testing to confirm the desired
steps.

1. [ ] Open a change issue if necessary
1. [ ] Stop Chef if necessary
1. [ ] Update the configuration item inside of [`chef-repo`] or the [`GKMS
   Vault`] as desired
1. [ ] Execute Chef as necessary
    * Monitor the nodes as necessary
1. [ ] Execute a Kubernetes pipeline
    * Monitor the pipeline and Infrastructure as necessary
1. [ ] If the change is secret related, Pods must be cycled manually
    * Use the console server to rotate all Pods

### Executing a Kubernetes pipeline

There are many options for this.  It is recommended to perform the following:

* Checkout a branch in [`k8s-workloads/gitlab-com`]
* Create an empty commit to [`k8s-workloads/gitlab-com`] with a commit that
  helps link a pipeline to an issue that is tracking the change.
  * `git commit --allow-empty --message 'Configuration Change for Issue <PATH TO
    ISSUE>`
  * Then push this `git push --set-upstream origin <branchname>`
* Performing this action will create a pipeline for which we can view the diff
  of the desired change prior to "merge"
* As a reminder, the pipelines are run on our Ops GitLab Instance

## Room For Improvement

Currently there are a few downsides that we are attempting to address:

* It's not visible anywhere which configurations or secrets are shared among
  each of these infrastructures.
  * Currently to accomplish this, requires a bit of domain knowledge as well as
    looking very closely at the above mentioned files for these values.
* The amount of shelling out and filtering being performed via `jq` are
  limitations by [`helmfile`] and the use of the Golang Sprig library today.  We
  are currently attempting to build a tool to make this much easier as this is
  very specific to our use case and desired SSOT.

One can follow improvements to the above in [Delivery Issue 699
](https://gitlab.com/gitlab-com/gl-infra/delivery/-/issues/699)

[`chef-repo`]: https://ops.gitlab.net/gitlab-cookbooks/chef-repo
[`helmfile`]: https://github.com/roboll/helmfile
[`k8s-workloads/gitlab-com`]: https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com
[`GKMS Vault`]: ./gkms-chef-secrets.md

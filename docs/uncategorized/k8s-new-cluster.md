# GitLab.com on Kubernetes

The following is a high level guide on what it takes to build out the necessary
bits for adding GKE and bringing over components of GitLab into Kubernetes.

Our current application configuration components:
* https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/common
* https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com
* https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles

# Creating a new GKE cluster

For GitLab.com there is a regional cluster and multiple zonal clusters to service traffic for each environment.
This document covers how to build a new cluster, note that currently this procedure is not automated and may take hours to complete.

### Provision the cluster in Terraform

* Three modules create the IP reservations needed for monitoring and ingress, the cluster and node pools, and external DNS, see [this example](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/blob/d6e0599570e70363456c1a1da8ab512b414f9a91/environments/gprd/gke-zonal.tf#L7-65) for one of the zonal clusters or the full [regional](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/blob/master/environments/gprd/gke-regional.tf) cluster terraform configuration.

* Set IAM user permissions on cluster
    * This is manual, documented here: https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/blob/master/README.md#service-account
    * The service account will have an authentication key file in json format created, we'll need this for the next step.
* Set the appropriate environment variables in the application configuration repositories:
    * Repositories:
      * https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/settings/ci_cd
      * https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/monitoring/-/settings/ci_cd
      * https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/common/-/settings/ci_cd
      * https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/settings/ci_cd
    * ENV Vars:
      * `SERVICE_KEY`
      * This key is gathered from following the documentation in the previous step and must be added to each repo since environment scoped group level variables are not a feature of GitLab
      * Environment names use wildcards to cover the zonal clusters, which are prefixed with `gprd` or `gstg`.

#### Configure gitlab-helmfile

See [bootstrapping new clusters](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/master/README.md#bootstrapping-new-clusters) for how to apply the initial set of helm charts on the cluster.

#### Prometheus rules:

* Inside of our `runbooks` repo, we need to add a configuration inside of `.gitlab-ci.yaml` to deploy to our new cluster.
* Ensure the appropriate variables are added to the ops instance Utilize this MR as a guideline: https://gitlab.com/gitlab-com/runbooks/merge_requests/1200

#### Thanos configuration

Thanos query needs to know about the prometheus endpoints, these are set in the [ops-base.json chef role](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/-/blob/31ed1e5fa4723bf9d2e837b0c0813c7c93f16b8a/roles/ops-base.json#L177-244)

### Configure gitlab-com

See [bootstrapping new clusters](https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/tree/master#bootstrapping-new-clusters) for how to apply the gitlab helm chart on the cluster.

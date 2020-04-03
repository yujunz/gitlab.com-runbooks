# GKE Cluster Upgrade Procedure

## Procedure

Each step below is a checkpoint for which an Merge Request should exist and is a
stopping point to allow one to breath before proceeding to the next step.

### Step 0

* Copy and paste the below procedure into a Change Request (summary through
  rollback procedure)
  * https://gitlab.com/gitlab-com/gl-infra/production/issues/new?issuable_template=change_c4
* Fill out the necessary details of the Change Request following our [Change
  Management Guidelines]
* Modify any `<Merge Request>` with a link to the merge request associated with
  that step
* Modify `<VERSION>` with the desired version we will be upgrading the GKE
  cluster to

### Summary

To upgrade our GKE Cluster to `<VERSION>`

### Step 1

* [ ] change node-pool config option `node_auto_upgrade` to `true` `<Merge
  Request>`
  * tf plan will indicate only change for the option `node_auto_upgrade`,
    nothing else
* [ ] execute a terraform apply
  * This is very quick change (a few seconds)

### Step 2

* [ ] change `kubernetes_version` to `<VERSION>` `<Merge Request>`
  * tf plan will indicate only _one_ change for the cluster configuration option
    `min_master_version`
* [ ] execute a terraform apply - This is roughly a 20 minute operation, so
  monitor the following:
* [ ] watch the following from
  `console-01-sv-gprd.c.gitlab-production.internal`:
  * `watch gcloud container clusters list`
  * `watch -n 5 kubectl get nodes`
  * `watch -n 5 kubectl get pods -o wide`
  * Monitor the gcloud operation:
    * Find the ID associated with the RUNNING cluster upgrade and do this:
    * `op_id=$(gcloud container operations list --region us-east1 | grep RUNNING
      | grep UPGRADE_MASTER | awk {'print $1'})`
    * `gcloud container operations wait $op_id --region us-east1`
  * wait for terraform and/or the gcloud operation being watched to complete
* [ ] Validate:
  * [ ] `kubectl version` - should indicate the server version matching the
    above
  * [ ] `gcloud container clusters list` - should indicate the new Kubernetes
    version and note that the nodes now require an upgrade

### Step 3

* [ ] change node-pool config option `node_auto_upgrade` to `false` `<Merge
  Request>`
  * tf plan will indicate _two_ changes for that node pool
    * setting `auto_upgrade` to `false`
    * setting `version` to that of the above
* [ ] tf apply will perform an upgrade of the node pool
  * the upgrade will be performed 1 node at a time, and 1 node pool at a time
  * :warning: terraform has a hard coded timeout for 10 minutes for this
    operation, though the operation will progress forward.  Note that if a tf
    apply timesout, and we've not reached all node pools, another `apply` must
    be run.
  * [ ] This is a lengthy operation (5 minutes per node) , so watch the
    following from `console-01-sv-gprd.c.gitlab-production.internal`:
    * `watch gcloud container clusters list`
    * `watch -n 5 kubectl get nodes`
    * `watch -n 5 kubectl get pods -o wide`
    * Monitor the gcloud operation:
      * Find the ID associated with the RUNNING nodes upgrade and do this:
      * `op_id=$(gcloud container operations list --region us-east1 | grep
        RUNNING | grep UPGRADE_NODES | awk {'print $1'})`
      * `gcloud container operations wait $op_id --region us-east1`
  * wait for terraform and/or the gcloud operation being watched to complete
* [ ] Validate:
  * [ ] `gcloud container clusters list` - should show the running node version
    matches above
  * [ ] `kubectl get nodes` - all nodes should be running the same version as
    noted above

### Rollback Procedure

There is no rollback procedure for the API.  Only node pools can be reversed,
but this would require a lot of mangling in terraform and is therefore not
documented.  All cluster operations should be tested using ephemeral
environments prior to performing on production.

The upgrade procedure should otherwise be considered safe and should not result
in any downtime on any running services.  One can view available GKE versions by
viewing the latest updates from the [GKE Release Notes]:


## Reasons Behind Certain Changes

### Step 1

* `node_auto_upgrade` set to `true` - this prevents the nodes from being
  upgraded at the same time the API nodes are upgraded.  Simply a safety measure
  and ensure that we are in as much control as possible and that any change to
  the API can be detected prior to upgrading nodes in case of issues.

### Step 2

* `kubernetes-version` set to `<VERSION>` - This performs the upgrade of the API
  nodes.

### Step 3

* `node_auto_upgrade` set to `false` - this seems awkward considering we just
  set it to `true` earlier, but this is when terraform will trigger GKE to
  perform the node upgrade.  Our module uses fancy replaces that will configure
  the auto_upgrade option to false, as well as setting the Kubernetes version
  appropriately.

### Overall

* Watching changes from the console server - in specific environments, we
  restrict the ability to reach the API nodes.  Our console servers will retain
  said access.
* Note that `tf apply` during a node upgrade may abort due to a timeout.  At
  this point, continue watching all of the items listed, more specifically, the
  `gcloud container operations wait` command.  When completed, perform a `tf
  plan` to ensure the terraform state matches that of the environment.  The
  timeout is a hard-coded item inside of the google provider and is therefore
  not configurable.

[Change Management Guidelines]: https://about.gitlab.com/handbook/engineering/infrastructure/change-management/
[GKE Release Notes]: https://cloud.google.com/kubernetes-engine/docs/release-notes

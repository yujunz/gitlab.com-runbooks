# GitLab

https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com

The following production services are running in the `gitlab` namespace:

* Container Registry
* Mailroom

## Setup for the oncall

- **!Important!** Before you do anything in this doc please follow the [setup instructions for the oncall](https://gitlab.com/gitlab-com/runbooks/blob/master/docs/uncategorized/k8s-operations.md)
- Ensure you can query Kubernetes gitlab namespace

```
kubectl -n gitlab get hpa
```

- Familiarize yourself with the deployment pipeline for GitLab on [ops.gitlab.net](https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/gitlab-com)

## Application Upgrading

* [CHART_VERSION](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/blob/dd201383641d01c5b5471012563a3079fdcdbdf1/CHART_VERSION)
  sets the version of the GitLab helm chart
* [gprd.yaml in k8s-worloads/gitlab-com](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/blob/dd201383641d01c5b5471012563a3079fdcdbdf1/gprd.yaml#L3-5)
  sets the version of the Registry image

To upgrade or downgrade the versions:

- submit an MR on a branch with a version update on
  [gitlab.com](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com)
- wait for the pipeline to pass and ensure the dry-run was successful on the
  [same branch on ops.gitlab.net](https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/gitlab-com)
- after approval, merge the MR to master and see that the change is applied to
  the non-production environments on [ops.gitlab.net](https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/gitlab-com)
- Manually promote the pipeline to production by running the manual CI job for
  the production deployment. Please be aware this will apply all pending changes.

### Failed Deploys

When deployments to environments fail, helm should automatically rollback the
application and mark the deployment job as failed.  Note that at this moment in
time, the application will not be upgraded, but the master branch of the repo
will contain the desired state that was not achievable.  One MUST address this
immediately.  If there's a failure to deploy, perform a revert of the commit
immediately to ensure the master branch represents what is in production.
Once the revert commit is in place, proceed to perform the necessary
investigation to continue towards the desired state.

## Creating a new node pool

Creating a new node pool will be necessary if we need to change the instance
sizes of our nodes or any setting that requires nodes to be stopped.

It is possible to create a new pool without any service interruption by
migrating workloads.

The following outlines the procedure, note that when doing this in production
you should create a change issue, see
https://gitlab.com/gitlab-com/gl-infra/production/issues/1192 as an example.

```
OLD_NODE_POOL=<name of old pool>
NEW_NODE_POOL=<name of new pool>
```

- Add the new node pool to terraform
- Apply the change and confirm the new node pool is created
- Cordon the existing node pool

```
for node in $(kubectl get nodes -l cloud.google.com/gke-nodepool=$OLD_NODE_POOL -o=name); do \
  kubectl cordon "$node"; \
  read -p "Node $node cordoned, enter to continue ..."; \
done

```

- Evict pods from the old node pool

```
for node in $(kubectl get nodes -l cloud.google.com/gke-nodepool=$OLD_NODE_POOL -o=name); do \
  kubectl drain --force --ignore-daemonsets --delete-local-data --grace-period=10 "$node"; \
  read -p "Node $node drained, enter to continue ..."; \
done
```

- Delete the old node pool manually (in GCP console or on the command line)
- Remove all node pools from the terraform state

```
tf state rm module.gitlab-gke.google_container_node_pool.node_pool[0]
tf state rm module.gitlab-gke.google_container_node_pool.node_pool[1]
```
- Import the new node pool into terraform

```
tf import module.gitlab-gke.google_container_node_pool.node_pool[0] gitlab-production/us-east1/gprd-gitlab-gke/$NEW_NODE_POOL
```

- Update terraform so that the new node pool is the only one in the list

## Monitoring and Troubleshooting

* All GKE logs: https://log.gprd.gitlab.net/goto/fcf1a37403d6a035e3dfd3a3b406bf34
* Registry errors in GKE: https://log.gprd.gitlab.net/goto/763017c05032e98ee79ef18165da7703
* Registry in GKE application overview: https://dashboards.gitlab.net/d/registry-app/registry-application-info?orgId=1
* Mailroom in GKE application overview: https://dashboards.gitlab.net/d/mailroom-app/mailroom-application-info?orgId=1
* Pod Metrics for Registry: https://dashboards.gitlab.net/d/registry-pod/registry-pod-info?orgId=1
* Pod Metrics for Mailroom: https://dashboards.gitlab.net/d/mailroom-pod/mailroom-pod-info?orgId=1&from=now-12h&to=now&var-PROMETHEUS_DS=Global&var-environment=gstg&var-cluster=gstg-gitlab-gke&var-namespace=gitlab&var-Node=All&var-Deployment=gitlab-mailroom
* General service metrics for Registry: https://dashboards.gitlab.net/d/general-service/general-service-platform-metrics?orgId=1&var-type=registry&from=now-1h&to=now

## Manual Scaling a Deployment

In times of emergency, whether it be a security issue, identified abuse, and/or
an incident where there's great pressure in our infrastructure, it may be
necessary to manually set the scale of a Deployment.  When a Deployment is setup
with a Horizontal Pod Autoscaler (HPA), and we need to manually scale, be aware
that the HPA will fail to autoscale if we scale down to 0 Pods.  Also keep in
mind that an HPA will process metrics on a regular cadence, if you scale w/i the
window of the HPA configuration, the manual override will quickly be taken over
by the HPA.

To scale a deployment, run the following example command:

```
kubectl scale <DEPLOYMENT_NAME> --replicas=<X>
```

Example, scale Deployment `gitlab-sidekiq-memory-bound-v1` to 0 Pods:

```
kubectl scale deployments/gitlab-sidekiq-memory-bound-v1 --replicas=0
```

The `DEPLOYMENT_NAME` represents the Deployment associated and managing the Pods
that are running.  `X` represents the desired number of Pods you wish to run.

After an event is over, the HPA will need at least 1 Pod running in order to
perform its task of autoscaling the Deployment.  For this, we can rerun a
similar command above, using the below as an example:

```
kubectl scale deployments/gitlab-sidekiq-memory-bound-v1 --replicas=1
```

Refer to existing Kubernetes documentation for reference and further details:
* https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
* https://github.com/kubernetes/community/blob/master/contributors/design-proposals/autoscaling/horizontal-pod-autoscaler.md

## Attaching to a running container

### Using Docker

Figure out what node/zone a Pod is running:

```
kubectl get pods -n gitlab -o wide # get the node name
node_name=<NODE_NAME>
zone=$(gcloud compute instances list --filter name=$node_name --format="value(zone)") # get the zone
```

SSH into the node:

```
gcloud compute ssh $node_name --zone=$zone
```

Discover which container we need to attach too

```
docker ps | grep <KEYWORD>
```

Example, we want to log into a specific sidekiq container:

```
$ docker ps | grep sidekiq-export-966444c8-sbpj5
56a476f72f30        4a879bb96135                                          "/scripts/entrypoint…"   6 hours ago         Up 6 hours                              k8s_sidekiq_gitlab-sidekiq-export-966444c8-sbpj5_gitlab_148e5cfb-21a2-11ea-b2f5-4201ac100006_0
f66cb9d37ec6        k8s.gcr.io/pause:3.1                                  "/pause"                 6 hours ago         Up 6 hours                              k8s_POD_gitlab-sidekiq-export-966444c8-sbpj5_gitlab_148e5cfb-21a2-11ea-b2f5-4201ac100006_0
```

You'll notice two containers are running, one using the `pause` image, and one
that is executing the entry point script.  The `pause` image is NOT the one you
are probably looking for.  Determining which container you need will greatly
depend on both the knowledge you have for the desired container and what
information you are trying to get too.  Knowing we need the first container
listed, we can then attach a new container to it:

```
docker run \
  -it \
  --pid=container:k8s_sidekiq_gitlab-sidekiq-export-966444c8-sbpj5_gitlab_148e5cfb-21a2-11ea-b2f5-4201ac100006_0 \
  --net=container:k8s_sidekiq_gitlab-sidekiq-export-966444c8-sbpj5_gitlab_148e5cfb-21a2-11ea-b2f5-4201ac100006_0 \
  --cap-add sys_admin \
  --cap-add sys_ptrace \
  ubuntu /bin/bash
```

In the above example we attached an alpine container running `sh` to the desired
sidekiq container we need.

At this point we can install whatever tooling necessary and interrogate the best
we can.  Note that we are provided a read only file system using this
troubleshooting method, so certain tooling may not properly work.  In instances
like this, we can try the `toolbox` documented [below](./#using-toolbox)

### Using Toolbox

GKE nodes by design have a very limited subset of tools. If you need to conduct troubleshooting directly on the host, consider using toolbox. Toolbox is a container that is started with the host's root filesystem mounted under `/media/root/`. The toolbox's file system is available on the host at `/var/lib/toolbox/`.

You can specify which container image you want to use, for example you can use `coreos/toolbox` or build and publish your own image. There can only be one toolbox running on a host at any given time.

For more details see: https://cloud.google.com/container-optimized-os/docs/how-to/toolbox

### Debugging containers in pods

Quite often you'll find yourself working with containers created from very small images that are stripped of any tooling. Installation of tools inside of those containers might be impossible or not recommended. Changing the definition of the pod (to add a debug container) will result in recreation of the pod and likely rescheduling of the pod on a different node.

One way to workaround it is to investigate the container from the host. Below are a few ideas to get you started.

#### Run a command with the pod's network namespace

1. Find the PID of any process running inside the pod, you can use the pause process for that (network namespace is shared by all processes/containers in a pod). There are many, many ways to get the PID, here are a few ideas:
    1. get PIDs and hostnames of all containers: `docker ps -a | tail -n +2 | awk '{ print $1}' | xargs docker inspect -f '{{ .State.Pid }} {{ .Config.Hostname }}'`
1. Once you have the PID, link its namespace where the `ip` command can find it (by default docker doesn't link network namespaces that it creates): `ln -sf /proc/<pid_you_found>/ns/net /var/run/netns/<your_custom_name>`
1. Run a command with the process' namespace
    1. Enter toolbox: `toolbox`
    1. List namespaces: `ip netns list`
    1. Run your command with the desired network namespace: `ip netns exec <your_custom_name> ip a`
1. Alternatively, you can use nsenter: `nsenter -target <PID> -mount -uts -ipc -net -pid`

#### Start a container that will use network and process namespaces of a pod

1. Get container id from PID: `cat /proc/<PID>/cgroup`
1. Get container name from container id: `docker inspect --format '{{.Name}}' "<containerId>" | sed 's/^\///'`
1. Create a container on the host: `docker run --rm -ti --net=container:<container_name> --pid=container:<container_name> --name ubuntu ubuntu bash`

For example:
```
$ docker run --rm --name pause --hostname pause gcr.io/google_containers/pause-amd64:3.0   # this is an example, it will run a simple container which you will connect to in a moment
$ docker run --rm -ti --net=container:pause --pid=container:pause -v /:/media/root:ro --name ubuntu ubuntu bash  # this will run an ubuntu container with network and process namespaces from the pause container and host's root file system mounted under /media/root
```

#### Share process namespace between containers in a pod

Share process namespace between containers in a pod: https://kubernetes.io/docs/tasks/configure-pod-container/share-process-namespace/

## Auto-scaling, Eviction and Quota

### Nodes

* Node auto-scaling: https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-autoscaler

Node auto-scaling is part of GKE's cluster auto-scaler, new nodes will be added
to the cluster if there is not enough capacity to run pods.

The maximum node count is set as part of the cluster configuration
for the
[node pool in terraform](https://gitlab.com/gitlab-com/gitlab-com-infrastructure/blob/7e307d0886f0725be88f2aa5fe7725711f1b1831/environments/gprd/main.tf#L1797)

### Pods

* Pod auto-scaling: https://cloud.google.com/kubernetes-engine/docs/how-to/scaling-apps

Pods are configured to scale by CPU utilization, targeted at `75%`

Example:
```
kubectl get hpa -n gitlab
NAME              REFERENCE                    TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
gitlab-registry   Deployment/gitlab-registry   47%/75%   2         100       21         11d
```

It is possible to scale pods based on custom metric but this is currently not
used in the cluster.

### Eviction

_Note: Evicted Pods are not removed by Kubernetes, it's perfectly normal to see some Evicted Pods in the list_

Automatic cleaning up of evicted pods is tracked in https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/7704

* Configuration for eviction when pods are out of resources https://kubernetes.io/docs/tasks/administer-cluster/out-of-resource/

Pods will be evicted when there is not enough resources, if there is a large
number of evictions this may point to a resource utilization error. To see
evicted pods:

```
kubectl get pods -a --all-namespaces
```

### Quota

There is a
[dashboard for monitoring the workload quota for production](https://dashboards.gitlab.net/d/kubernetes-resources-workload/kubernetes-compute-resources-workload?orgId=1&refresh=10s&var-datasource=Global&var-cluster=gprd-gitlab-gke&var-namespace=gitlab&var-workload=gitlab-registry&var-type=deployment) that shows the memory quota.
The memory threshold is configures in the
[kubernetes config for Registry](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/blob/4b7ba9609f634400e500b3ac54aa51240ff85b27/gprd.yaml#L6)

If a large number of pods are being evicted it's possible that increasing the
requests will help as it will ask Kubernetes to provision new nodes if capacity
is limited.

Kubernetes Resource Management: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/

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
> necessary: `sudo chown -R $(id) ~/.config`

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

* All GKE logs: https://log.gitlab.net/goto/fcf1a37403d6a035e3dfd3a3b406bf34
* Registry errors in GKE: https://log.gitlab.net/goto/763017c05032e98ee79ef18165da7703
* Registry in GKE application overview: https://dashboards.gitlab.net/d/CoBSgj8iz/application-info?orgId=1
* Pod Metrics: https://dashboards.gitlab.net/d/oWe9aYxmk/pod-metrics?orgId=1&refresh=30s
* General service metrics for Registry: https://dashboards.gitlab.net/d/general-service/general-service-platform-metrics?orgId=1&var-type=registry&from=now-1h&to=now

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
1. Create a container on the host: `docker run --rm -ti --net=container:<container_name> --pid=container:<conatiner_name> --name ubuntu ubuntu bash`

For example:
```
$ docker run --rm --name pause --hostname pause gcr.io/google_containers/pause-amd64:3.0   # this is an example, it will run a simple container which you will connect to in a moment
$ docker run --rm -ti --net=container:pause --pid=container:pause -v /:/media/root:ro --name ubuntu ubuntu bash  # this will run an ubuntu container with network and process namespaces from the pause container and host's root file system mounted under /media/root
```

#### Share process namespace between containers in a pod

Share process namespace between containers in a pod: https://kubernetes.io/docs/tasks/configure-pod-container/share-process-namespace/

## Credential rotation

:warning: **Be careful with secrets as an invalid configuration may cause a service outage** :warning:

There are three secrets for the registry service, the way they are configured in
the cluster is described in the [HELM_README](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/blob/dd201383641d01c5b5471012563a3079fdcdbdf1/HELM_README.md#secret-for-gcs-configuration).

* **registry-storage** - for accessing object storage, local to the registry service
  and contains the json credential for the service account. To rotate this
  credential export a new json key from the console.
* **registry-httpsecret** - random data used to sign state, local to the registry service. To create a new secret follow the generation
  [instructions in the GitLab chart](https://docs.gitlab.com/charts/installation/secrets.html#registry-http-secret)
* **registry-certificate** - this secret must match the key configured in rails. To create a new secret follow the
  [generation instructions in the GitLab chart](https://docs.gitlab.com/charts/installation/secrets.html#registry-authentication-certificates)


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

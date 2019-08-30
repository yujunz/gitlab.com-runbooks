## Workstation setup for the oncall

Configuration changes are handled through GitLab CI so most of what we do does
not require interacting with the cluster directly. As an oncall SRE, you should
also setup your workstation to query the kubernetes API with `kubectl`.

- [ ] Get the credentials for production, staging and preprod:

```
gcloud container clusters get-credentials pre-gitlab-gke --region us-east1 --project gitlab-pre
gcloud container clusters get-credentials gstg-gitlab-gke --region us-east1 --project gitlab-staging-1
gcloud container clusters get-credentials gprd-gitlab-gke --region us-east1 --project gitlab-production
```
- [ ] Install `kubectl` https://kubernetes.io/docs/tasks/tools/install-kubectl/
- [ ] Install `helm` 2.x https://helm.sh/docs/using_helm/#install-helm
- [ ] Install `kubectx` https://github.com/ahmetb/kubectx
- [ ] Test to ensure you can list the installed helm charts in staging and production

```
cd /path/to/gl-infra/k8s-workloads/gitlab-com
./bin/k-ctl -e gprd list
```

- [ ] Switch to the production cluster kubectx

```
kubectx gke_gitlab-production_us-east1_gprd-gitlab-gke
```

- [ ] Get the current horizontal pod autoscaler status for production

```
kubectl -n gitlab get hpa
```

- [ ] Familiarize yourself with the deployment pipeline for registry, see an
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

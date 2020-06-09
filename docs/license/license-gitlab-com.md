# license.gitlab.com Runbook

### Overview

The `license.gitlab.com` application is the license management app for customers and sales people to manage the licenses that customers use.  The  primary functions of this app are:

1. Allow management of licenses to support and sales personnel
2. Mail license information to customers

This is an internally developed Rails app which is running on a GKE cluster, using an unmodified Auto DevOps deployment configuration. The production database is CloudSQL, and the staging/review databases currently run in pods provisioned by Auto DevOps.

> The use of tools built into the GitLab product, in favor of technically better external solutions is intentional. The goal is to dogfood the operations and monitoring tools within the product, and use the discovered shortcomings to drive improvements to those areas. Building out tooling to work around these shortcomings is contrary to this goal.

### Setup for On Call

- Read the README file for the [GitLab Services Base](https://ops.gitlab.net/gitlab-com/services-base) project
- Note the location of the [Metrics Dashboards](https://gitlab.com/gitlab-org/license-gitlab-com/-/environments/1764604/metrics)
- Note the location of the [CI Pipelines for the infrastructure](https://ops.gitlab.net/gitlab-com/services-base/pipelines) components
- Note the location of the [CI Pipelines for the application](https://gitlab.com/gitlab-org/license-gitlab-com/pipelines) components

#### Workstation K8s Connection Setup

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
gcloud container clusters get-credentials license-stg-gke --region us-east1 --project license-stg-8ba766
gcloud container clusters get-credentials license-prd-gke --region us-east1 --project license-prd-bfe85b
```

> Note that the hash after the project name may change without this documentation being updated. If in doubt, check the GCP console for the new hash.

This should add the appropriate context for `kubectl`, so the following should
work and display the nodes running on the cluster:

- [ ] `kubectl get nodes`

### Deployment

The application is deployed using Auto DevOps from the [license-gitlab-com](https://gitlab.com/gitlab-org/license-gitlab-com/) project. It uses a Review/Staging/Production scheme with no `.gitlab-ci.yml` file. If deployment problems are suspected, check for [failed or incomplete jobs](https://gitlab.com/gitlab-org/license-gitlab-com/pipelines), and check the [Environments](https://gitlab.com/gitlab-org/license-gitlab-com/-/environments) page to make sure everything looks reasonable. 


### Project

The production deployment of the `license.gitlab.com` application is in the `license-prd` GCP project. The components to be aware of are:

- The Kubernetes cluster `license-prd-gke` and its node pool
- CloudSQL instance `cloudsql-4bf6` (the 4 character suffix is necessary for terraform and will change with future deployments)
- Load balancer (provisioned by the k8s ingress)
- Storage bucket `license-prd-data` holds manual database exports. Do a manual export before any operations which touch cloudSQL, since it has been observed to lose data during operations which should be safe.

The review and staging deployments share the `license-stg` GCP project. The Kubernetes cluster is similar, but the databases are deployed as pods, so there is no CloudSQL instance

### Database

The production database resides in a regional (`us-east1`) HA CloudSQL instance. Currently this is `cloudsql-4bf6` (but could change if it is rebuilt). 

The database schema for the license application is `default`. The username and password can be found in the `DATABASE_URL` CI variable in the project settings.

Database backups are handled automatically by CloudSQL, and can be restored from the `Backups` tab of the CloudSQL instance.  There are also occasional exports placed in the `license-prd-data` bucket. These will not be as up to date, but they are easier to copy and move around.


### Terraform

This GCP project and the infrastructure components in it are managed by the [services-base](https://ops.gitlab.net/gitlab-com/services-base) project.  Any infrastructure changes to the environment or K8s cluster should be made as an MR there.  Changes will be applied automatically via CI jobs when the MR is merged.  `license-prd` and `license-stg` are represented as [Environments](https://ops.gitlab.net/gitlab-com/services-base/environments) in that project.

This workflow is different from other areas of the infrastructure. `services-base` uses the [GitLab Flow Workflow](https://docs.gitlab.com/ee/university/training/gitlab_flow.html#production-branch). There is currently no manual step between `terraform plan` and `terraform apply`.  The assumption is that an ephemeral environment in a review stage doesn't need this, and for a production environment any change must have successful pipelines in both the review stage and the master merge before they can be applied to the production branch.  We may revisit this as these environments mature.

### Monitoring

Monitoring is handled from within the GitLab application, using the [built in monitoring functionality](https://gitlab.com/gitlab-org/license-gitlab-com/-/environments/1764604/metrics).  This is done to dogfood the built in monitoring tools.  Any shortcomings should be pointed out using [GitLab Product issues](https://gitlab.com/gitlab-org/gitlab/issues) and labelled for the Monitor team.  The Prometheus instance used is deployed via the [Kubernetes Integration](https://gitlab.com/gitlab-org/license-gitlab-com/-/clusters/99932?tab=apps) page.

### Checking the Ingress

Switch contexts to the `license-prd-gke` cluster in the `license-prd` namespace.

Make sure there is at least one ingress controller pod, and that it hasn't been restarting. Note the age and restart count in the below example output.

```
% kubectl get pods -n gitlab-managed-apps -l app=nginx-ingress
NAME                                                     READY   STATUS    RESTARTS   AGE
ingress-nginx-ingress-controller-85ff56cfdd-cjd9b        1/1     Running   0          24h
ingress-nginx-ingress-controller-85ff56cfdd-fmqnh        1/1     Running   0          24h
ingress-nginx-ingress-controller-85ff56cfdd-tg77w        1/1     Running   0          46h
ingress-nginx-ingress-default-backend-76d9f87474-xm66d   1/1     Running   0          46h

```

Check for Events:

```
kubectl describe deployment -n gitlab-managed-apps ingress-nginx-ingress-controller
```
 The bottom of this output will show health check failures, pod migrations and restarts, and other events which might effect availability of the ingress. `Events: <none>` means the problem is probably elsewhere.

After 1 hour, these events are removed from the output, so historical information can be found in the [stackdriver logs](https://console.cloud.google.com/logs/viewer?interval=NO_LIMIT&project=license-prd-bfe85b&minLogLevel=0&expandAll=false&timestamp=2020-05-29T22:31:36.584000000Z&customFacets=&limitCustomFacetWidth=true&scrollTimestamp=2019-11-08T21:11:28.371054395Z&angularJsUrl=%2Flogs%2Fviewer%3Finterval%3DNO_LIMIT%26project%3Dlicense-prd-bfe85b%26minLogLevel%3D0%26expandAll%3Dfalse%26timestamp%3D2019-11-08T21:11:39.147000000Z%26customFacets%3D%26limitCustomFacetWidth%3Dtrue%26advancedFilter%3Dresource.type%253D%2522k8s_container%2522%250Aresource.labels.project_id%253D%2522license-prd-bfe85b%2522%250Aresource.labels.location%253D%2522us-east1%2522%250Aresource.labels.cluster_name%253D%2522license-prd-gke%2522%250Aresource.labels.namespace_name%253D%2522gitlab-managed-apps%2522%250Alabels.k8s-pod%252Fapp%253D%2522nginx-ingress%2522%250Alabels.k8s-pod%252Frelease%253D%2522ingress%2522%26scrollTimestamp%3D2019-11-08T21:11:28.371054395Z&authuser=1&advancedFilter=resource.type%3D%22k8s_container%22%0Aresource.labels.project_id%3D%22license-prd-bfe85b%22%0Aresource.labels.location%3D%22us-east1%22%0Aresource.labels.cluster_name%3D%22license-prd-gke%22%0Aresource.labels.namespace_name%3D%22gitlab-managed-apps%22%0Alabels.k8s-pod%2Fapp%3D%22nginx-ingress%22%0Alabels.k8s-pod%2Frelease%3D%22ingress%22)

### Rebuilding or upgrading the ingress

Currently, the integration does not have a way to upgrade components. To upgrade the ingress controller:

1. Submit a [production change issue](https://gitlab.com/gitlab-com/gl-infra/production/issues/new?issue%5Bassignee_id%5D=&issue%5Bmilestone_id%5D=) to schedule a maintenance window
2. Go to the Kubernetes integration page, and uninstall the ingress controller
3. Once it finishes, click the install button
4. The IP address will change.  Take this new IP address and replace the existing one in the DNS for the wildcard entry on that page, as well as any site specific entries (`license.gitlab.com` in this case).  

### Certificates

Certificates are managed by the `cert-manager` pod installed via the [Kubernetes Integration](https://gitlab.com/gitlab-org/license-gitlab-com/-/clusters/99932?tab=apps) page. This will handle automatic renewals. All of this only works if all DNS entries named in the certificate point to the ingress IP. 

### DNS

DNS is hosted in route53, and is managed via terraform in the [gitlab-com-infra repository](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/tree/master/environments/dns)

### Resources

Switch contexts to the `license-prd-gke` cluster in the `license-prd` namespace.

The overall usage can be checked like this:

```
$ kubectl top nodes 
NAME                                              CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
gke-license-prd-gke-node-pool-0-08bfc75b-v8dk   132m         1%     3183Mi          11%
gke-license-prd-gke-node-pool-0-a6855491-hrx5   125m         1%     2534Mi          9%
gke-license-prd-gke-node-pool-0-e198996d-jwk0   178m         2%     1705Mi          6%
```

Pods can be checked like this:

```
kubectl top pods --all-namespaces
NAMESPACE                               NAME                                                        CPU(cores)   MEMORY(bytes)
gitlab-managed-apps                     certmanager-cainjector-8476655b56-pcp5t                     5m           17Mi
gitlab-managed-apps                     certmanager-cert-manager-6b8946b5bb-rgj2b                   3m           13Mi
gitlab-managed-apps                     certmanager-cert-manager-webhook-8498494f89-wm4zl           1m           11Mi
gitlab-managed-apps                     ingress-nginx-ingress-controller-65dc55d79b-m5p4r           7m           175Mi
gitlab-managed-apps                     ingress-nginx-ingress-default-backend-7789656965-cfxxr      1m           5Mi
gitlab-managed-apps                     prometheus-kube-state-metrics-78cb8c6f9d-b7www              2m           9Mi
gitlab-managed-apps                     prometheus-prometheus-server-78bdf8f5b7-gfrwp               8m           179Mi
gitlab-managed-apps                     runner-gitlab-runner-d6c545d65-9p5vj                        7m           14Mi
gitlab-managed-apps                     tiller-deploy-6dc7b49d5f-kszlx                              1m           7Mi
kube-system                             event-exporter-v0.3.0-5cd6ccb7f7-plfr7                      1m           26Mi
kube-system                             fluentd-gcp-scaler-6855f55bcc-2dg9s                         0m           94Mi
kube-system                             fluentd-gcp-v3.1.1-g4fdn                                    10m          178Mi
kube-system                             fluentd-gcp-v3.1.1-gbgnz                                    11m          172Mi
kube-system                             fluentd-gcp-v3.1.1-nflql                                    11m          183Mi
kube-system                             heapster-gke-b45f54bb4-r6l47                                1m           54Mi
kube-system                             kube-dns-5c446b66bd-64fcj                                   3m           44Mi
kube-system                             kube-dns-5c446b66bd-w76w9                                   3m           44Mi
kube-system                             kube-dns-autoscaler-6b7f784798-kvnd9                        1m           6Mi
kube-system                             kube-proxy-gke-license-prd-gke-node-pool-0-2c3c2162-11qp    2m           19Mi
kube-system                             kube-proxy-gke-license-prd-gke-node-pool-0-d7e7c88f-z6m5    2m           19Mi
kube-system                             kube-proxy-gke-license-prd-gke-node-pool-0-e72d5cf1-q1rq    2m           19Mi
kube-system                             l7-default-backend-84c9fcfbb-t2lrj                          1m           4Mi
kube-system                             metrics-server-v0.3.3-7599dd85cd-8n4vn                      2m           28Mi
kube-system                             prometheus-to-sd-ln7qt                                      3m           19Mi
kube-system                             prometheus-to-sd-ngw64                                      1m           19Mi
kube-system                             prometheus-to-sd-sspkl                                      0m           20Mi
kube-system                             stackdriver-metadata-agent-cluster-level-59d79c8d48-msx48   4m           33Mi
kube-system                             tiller-deploy-58565b5464-6jn8w                              1m           8Mi
license-gitlab-com-6457868-production   production-77458795fb-srltp                                 1m           119Mi
```

### Alerting

Currently, the only alerting is the pingdom blackbox alerts.  This is the same as what was set up in the previous AWS environment, but probably needs to be improved.  The preference is to use built in GitLab functionality where possible.

There is work to improve the current alerting mechanism inside of the GitLab product.  This work can be followed here: https://gitlab.com/gitlab-org/gitlab/issues/30832


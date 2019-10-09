# PlantUML

https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/plantuml

## Setup for the oncall

- **!Important!** Before you do anything in this doc please follow the [setup instructions for the oncall](https://gitlab.com/gitlab-com/runbooks/blob/master/howto/k8s-operations.md)
- Ensure you can query Kubernetes gitlab namespace

```
kubectl -n plantuml get hpa
```

- Familiarize yourself with the deployment pipeline for GitLab on [ops.gitlab.net](https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/plantuml)

## Workstation setup for the oncall

- Follow the setup instructions [workstation setup for the oncall](https://gitlab.com/gitlab-com/runbooks/blob/master/howto/k8s-gitlab-operations.md#workstation-setup-for-the-oncall)
- Ensure you can query Kubernetes plantuml namespace

```
kubectl -n plantuml get hpa
```

- Familiarize yourself with the deployment pipeline for PlantUML on [ops.gitlab.net](https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/plantuml)

## Application Upgrading

* `CHART_VERSION` which is set in the [configuration project](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/plantuml/blob/7850985e67984d363b31ed888674325fab84e03b/CHART_VERSION)
* NGinx version which is a [value in the chart](https://gitlab.com/gitlab-org/charts/plantuml/blob/8d080485f58020a08b75a889f1fb81159fa93195/values.yaml#L18)
* PlantUML version which is a [value in the chart](https://gitlab.com/gitlab-org/charts/plantuml/blob/8d080485f58020a08b75a889f1fb81159fa93195/values.yaml#L13) and set as an [override in the env files](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/plantuml/blob/a610ec027f02e07312a33add1f333df409ca978e/gprd.yaml#L10). This is set to a `sha256` until https://gitlab.com/gitlab-com/gl-infra/delivery/issues/475 is resolved

To upgrade or downgrade the versions:

- submit an MR on a branch with a version update on
  [gitlab.com](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/plantuml)
- wait for the pipeline to pass and ensure the dry-run was successful on the
  [same branch on ops.gitlab.net](https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/plantuml)
- after approval, merge the MR to master and see that the change is applied to
  the non-production environments on [ops.gitlab.net](https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/plantuml)
- Manually promote the pipeline to production by running the manual CI job for
  the production deployment. Please be aware this will apply all pending changes.

## Monitoring and Troubleshooting

* There are multiple dashboards for monitoring both the GKE cluster and
  performance of the application:
  * [Workloads for PreProd](https://dashboards.gitlab.net/d/kubernetes-resources-workload/kubernetes-compute-resources-workload?orgId=1&refresh=10s&var-datasource=Global&var-cluster=pre-gitlab-gke&var-namespace=plantuml&var-workload=plantuml&var-type=deployment): Monitoring scaling and resources
  * [Pods for PreProd](https://dashboards.gitlab.net/d/kubernetes-resources-pod/kubernetes-compute-resources-pod?orgId=1&refresh=10s&var-datasource=Global&var-cluster=pre-gitlab-gke&var-namespace=plantuml&var-pod=plantuml-7f6b9b6894-nwzfm): Metrics for individual pods
  * [Overview dashboard for prepod](https://dashboards.gitlab.net/d/plantuml-main/plantuml-overview?orgId=1&var-PROMETHEUS_DS=Global&var-environment=pre&var-cluster=pre-gitlab-gke): Status codes and latencies

_Note: these links are for pre-prod, update them by selecting the production cluster or production env_

JSON logs are configured by default for Nginx which will allow us to monitor the
service during the rollout for rate limiting

Example for pre-production: https://nonprod-log.gitlab.net/goto/1409380492c985230a87b5af5dafe621

## CDN and Caching

All images are cached aggressively at the L7 LB which provides a CDN. Under some
circumstances, it may be necessary to send a cache invalidation, this is done
using the GCP console.

Example for pre-production: https://console.cloud.google.com/net-services/cdn/list?project=gitlab-pre&cdnOriginsTablesize=50

* To reset the cache for all diagrams, send a cache invalidation for `/png/*`

## Resource Limits

PlantUML has per environment requests and resource limits, configured in the
[`k8s-workloads/plantuml` project](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/plantuml/blob/7850985e67984d363b31ed888674325fab84e03b/pre.yaml#L14-20)

## Updating secrets

PlantUML has a single secret `plantuml-cert` which is the SSL certificate for
the L7 LB created in GCP. To update this certificate when it is close to expiration
follow the secret instructions in the project
[README.md](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/plantuml/blob/c821508531a7610722174430eb63cfe1b9891304/README.md).

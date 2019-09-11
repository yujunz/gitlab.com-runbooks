## Workstation setup for the oncall

- Follow the setup instructions [workstation setup for the oncall](https://gitlab.com/gitlab-com/runbooks/blob/master/howto/k8s-gitlab-operations.md#workstation-setup-for-the-oncall)
- Ensure you can query Kubernetes plantuml namespace

```
kubectl -n plantuml get hpa
```

- Familiarize yourself with the deployment pipeline for PlantUML on [ops.gitlab.net](https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/plantuml)

## Application Upgrading

* `CHART_VERSION` which is set in the [configuration project](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/plantuml/blob/7850985e67984d363b31ed888674325fab84e03b/CHART_VERSION)
* NGinx version which is a [value in the chart](https://gitlab.com/gitlab-com/gl-infra/charts/plantuml/blob/8d080485f58020a08b75a889f1fb81159fa93195/values.yaml#L18)
* PlantUML version which is a [value in the chart](https://gitlab.com/gitlab-com/gl-infra/charts/plantuml/blob/8d080485f58020a08b75a889f1fb81159fa93195/values.yaml#L13).
  This is set to `latest` until a version is tagged upstream, which is a [pending change for plantuml-server](https://github.com/plantuml/plantuml-server/pull/115)
  PlantUML

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


## Resource Limits

PlantUML has per environment requests and resource limits, configured in the
[`k8s-workloads/plantuml` project](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/plantuml/blob/7850985e67984d363b31ed888674325fab84e03b/pre.yaml#L14-20)

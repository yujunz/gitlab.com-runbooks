# Blackbox git exporter is down

## Symptoms
* Message in prometheus-alerts _Blackbox git [pulls|pushes] over [https|ssh] are taking too long._

## Check dashboards

* Check the [timings dashboard](https://dashboards.gitlab.net/dashboard/db/gitlab-com-git-timings) to
see if the problem is specific to particular nfs shard or is the same across all storage nodes.
* Check the [host dashboard](https://dashboards.gitlab.net/dashboard/db/host-stats) if there appears to
be problems on a specific storage node.

## Verify the blackbox exporter is working properly

The exporter is a container running on GKE and the repository can be found [here](https://gitlab.com/gl-infra/prometheus-git-exporter). CD is enabled on this repo so make sure to check out [the latest pipelines](https://gitlab.com/gl-infra/prometheus-git-exporter/pipelines): maybe something went off with a recent change that got automatically deployed.

To connect to the cluster run this:

```
gcloud container clusters get-credentials external-blackbox-us-west1 --zone us-west1-a --project <the project ID>
```

Then you should be able to see the pods with `kubectl get pods -l app=prometheus-git-exporter`.

To take a look at the logs use `kubectl logs prometheus-git-exporter-<chars>-<more chars> -f --tail=50` where `-f` follows the output and `--tail` limits the output to the last 50 lines, otherwise **all** the log lines since the pod inception will be printed.

If you're still unsure what's going on you can even log into the container with `kubectl exec -ti prometheus-git-exporter-<chars>-<more chars> sh` and take a look around.

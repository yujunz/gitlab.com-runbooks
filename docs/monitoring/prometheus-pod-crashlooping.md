# Prometheus pod crashlooping

A Prometheus Kubernetes pod is crashlooping.

## Common symptoms

### Out of memory

Increase the memory: https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/blob/master/releases/30-gitlab-monitoring/gprd.yaml.gotmpl

Ensure that we have enough cluster-level headroom to accommodate this. As of
today, there is no simple, single procedure to ensure this.

### Persistent disk full

This is actually often a symptom of OOM kills: the crashlooping process will
begin to write out some WAL on each boot, until the disk is full.

Mitigations:

```
# Open an ssh tunnel to the relevant cluster
sshuttle -r console-01-sv-gprd.c.gitlab-production.internal '35.243.230.38/32' # gprd

# Get a shell on a container that has access to the volume. If prometheus itself
# is down for a long crashloop, you can use thanos-sidecar:
kubectl --context gprd -n monitoring exec -it prometheus-gitlab-monitoring-promethe-prometheus-1 -c thanos-sidecar sh

# In that pod shell:
df -h

# Clean out temporary dirs, **only if the prometheus container is indeed not
# running**
rm -rf /prometheus/*.tmp

# Check the disk usage again:
df -h

# As a last resort, delete some WAL. This will cause data loss of metrics
# ingested since the last commit on this replica. This might be acceptable, as
# we can rely on our hopefully-healthy redundant replica(s) to retain this data
# and ship it to thanos.
rm -rf /prometheus/wal/*
```

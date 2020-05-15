# Accessing a GKE Alertmanager

This should be a temporary way to access Alertmanager for our GKE
infrastructure.
[Original reference](https://gitlab.com/gitlab-com/gl-infra/delivery/-/issues/733#note_306622484).

You should have already configured console `kubectl` access for these steps
to work. [K8s For Operations](../uncategorized/k8s-operations.md)

1. Log into the console server, get the service to access, and initiate a
   port-forward command:
   * `ssh console-01-sv-gprd.c.gitlab-production.internal`
   * `kubectl get svc -n monitoring`
   * `kubectl port-forward -n monitoring svc/gitlab-monitoring-promethe-alertmanager 9093:9093`
2. Build a tunnel to the console:
   * `ssh -NL 9093:localhost:9093 console-01-sv-gprd.c.gitlab-production.internal`
3. Open `http://localhost:9093` in a local browser.

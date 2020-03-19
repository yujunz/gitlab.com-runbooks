# Praefect error rate is too high

## Symptoms

* Message in prometheus-alerts _Praefect error rate is too high_

## 1. Check the prometheus dashboard

- Visit the **[Praefect Dashboard](https://dashboards.gitlab.net/d/8EAXC-AWz/praefect)**.
- Notice if any error type is spiking.

## 2. Check for suspicious errors in Kibana

Filter by index pattern `pubsub-praefect-inf-gprd*`

Search for:

- "all SubConns are in TransientFailure" - Indicates there may be a node that praefect cannot reach

- "PermissionDenied" - Indicates there is a mismatch between the token field under a `[virtual_storage.node]`, and the token under `[auth]` in the corresponding Gitaly config.toml.

## 3. Identify the problematic instance

- Go to https://dashboards.gitlab.net/dashboard/db/praefect?panelId=2&fullscreen and
identify the instance with a high error rate.
- ssh into that instance and check the log for its Praefect server for post-mortem:

```
sudo less /var/log/gitlab/praefect/current
```


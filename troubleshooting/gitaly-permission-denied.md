# Gitaly PermissionDenied alert

## Symptoms

* Alert on Slack: _Gitaly authention failing, authentication tokens might be misconfigured, or severe clockdrift is occuring._
* Low SLA for the Gitaly service because of PermissionDenied gRPC status codes

## 1. Review the PermissionDenied errors

- **Search for nodes serving PermissionDenied gRPC status codes**: https://dashboards.gitlab.net/d/xSYVQ9Sik/gitaly-feature-error-diagnostics?orgId=1&refresh=5m
- These nodes either have clock drift, as HMAC uses time as a nonce for authentication. Keep in mind that this is an open-ended alert, so it alerts to suspicious activity, rather than pin-pointing an issue.
- If a lot of different nodes are affected, it might be a misconfiguration of the Gitaly or frontend node.
- Use this prometheus query to see what type of error it is: `sum(gitaly_authentication_errors_total) by (error)`

## 2. Evaluate impact

- If the affected nodes are limited, consider synchronizing the clocks with NTPd.
- If the authentication tokens don't match, consider the following steps:
  1. Temporarly disable authentication for Gitaly, by setting `transitioning` to `true`: https://docs.gitlab.com/ee/administration/gitaly/reference.html#authentication in the Gitaly config.
  2. Update the Authentication tokens throughout the fleet to match, and restart the nodes
  3. Observe that Gitaly accepts the tokens using Prometheus: `gitaly_authentications_total{status!="ok"}`
  4. Once the counter stops moving, remember to set `transitioning` back to `false`, and undo step 1.
# deadman switches

## Purpose and implementation

The main purpose of a deadman switch, is to observe if a given task or action has reported back in a given time. This can be used in variuos scenarios, where active monitoring is not applicable, such as cron jobs, or scheduled pipeline executuions. If there would fail to check back in the targeted interval an alert would fire, informing about this incident.

This is implementated via prometheus pushgateways and alert-manager. To register and check-in a successful execution the cron/pipeline publish a metric with the current timestamp (see below for details). This in tunrn is evaluated to the current time in alert-manager. Should the time difference be greater than the defined time it would trigger the alert.

## Visibility

The current check-ins for deadman switches can be visualized on this dashboard: [Deadman Switches](https://dashboards.gitlab.com/d/_FOpntlmz/deadman-switches?orgId=1)

## Creatin and updating a new deadman switch

Creating a new deadman switch is the same process as checking-in/updating. This is driven by convention over configuration. It is enough to publish a metric with an arbitrary `resource` label, specifying the resource that the alert reports on. This could be a URL to a repository and the job name in case of a scheduled pipeline, but must not include data, that changes between invocations (e.g. pipeline or job IDs). In addition to that the `type` and `tier` labels are required, as per all our alerts. These should correspond with the type and tier of the underlying service, that the deadman switch is monitoring.

Currently implemented intervals are 15m, 30m 6h and 1d. Be aware, that is is not easily possible to change the repoting time, without triggering the old alerts. In case of changes the old alerts should be silenced.

The metric to be exported will be `deadman_<interval>_checkin` (with the labels mentioned above) and has to be a valid unix-timestamp in seconds.

The below code can be used within a bash script (after having exported the respective environment variables)

```bash
cat <<EOF | curl -iv --data-binary @- "http://${GATEWAY}:9091/metrics/job/deadman_checkin/tier/${TIER}/type/${TYPE}"
# TYPE deadman_${INTERVAL}_checkin counter
deadman_${INTERVAL}_checkin{resource="${RESOURCE}"} $(date +%s)
EOF
```

| Variable | Description |
| -------- | ----------- |
| `GATEWAY` | The hostname/IP of the pushgateway to push to (check firewalls, stay within environment if possible) |
| `INTERVAL` | THe targeted report interval (selection of `15m`, `30m`, `6h` or `1d`) |
| `RESOURCE` | The resource identifier to include in alerts. Do not include data, that changes between invocations (such as pipeline or job IDs for example) |
| `TIER` | The tier of the monitored service (e.g. `db`) |
| `TYPE` | The tpye of the monitored service (e.g. `postgres`)

## Alerting

Any deadman switch created like above automatically has alerting enabled. These alerts will be sent out to pagerduty as critical. If this should not be the case, please create the appropriate silence in alert-manager by silencing the alert for the resource.
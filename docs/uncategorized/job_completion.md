# GitLab Job Completeion

## Purpose and implementation

The main purpose of a job completion metric is to observe if a given task or action has successfully run in the required interval. This can be used in variuos scenarios, where active monitoring is not applicable, such as cron jobs, or scheduled pipeline executuions. If there would fail to check back in the targeted interval an alert would fire, informing about this incident.

This is implementated via Prometheus Pushgateway. To register and check-in a successful execution the cron/pipeline publish the required metrics to a Pushgateway. See below for details. Should the time difference be greater than the defined time it would trigger the alert.

## Creatin and updating a new job metric

Creating a new job completion metric is the same process as checking-in/updating. This is driven by convention over configuration. It is enough to publish a metric with an arbitrary `resource` label, specifying the resource that the alert reports on. This could be a URL to a repository and the job name in case of a scheduled pipeline, but must not include data, that changes between invocations (e.g. pipeline or job IDs). In addition to that the `type` and `tier` labels are required, as per all our alerts. These should correspond with the type and tier of the underlying service, that the deadman switch is monitoring.

Three metrics are required:

| Metric                                  | Description  |
| --------------------------------------- |  |
| `gitlab_job_max_age_seconds`            | This is the allowed age before the alert should fire, in seconds. |
| `gitlab_job_start_timestamp_seconds`    | This is the unix time in seconds when the job starts.  |
| `gitlab_job_success_timestamp_seconds`  | This is the unix time in seconds when the job completes succesfully. It should be set to 0 at job start. |

The below code can be used within a bash script (after having exported the respective environment variables)

`report_start.sh`:

```bash
cat <<EOF | curl -iv --data-binary @- "http://${GATEWAY}:9091/metrics/job/deadman_checkin/tier/${TIER}/type/${TYPE}"
# TYPE gitlab_job_start_timestamp_seconds gauge
gitlab_job_start_timestamp_seconds{resource="${RESOURCE}"} $(date +%s)
# TYPE gitlab_job_success_timestamp_seconds gauge
gitlab_job_success_timestamp_seconds{resource="${RESOURCE}"} 0
# TYPE gitlab_job_max_age_seconds gauge
gitlab_job_max_age_seconds{resource="${RESOURCE}"} ${MAX_AGE}
EOF
```

`report_success.sh`:
```bash
cat <<EOF | curl -iv --data-binary @- "http://${GATEWAY}:9091/metrics/job/deadman_checkin/tier/${TIER}/type/${TYPE}"
# TYPE gitlab_job_success_timestamp_seconds gauge
gitlab_job_success_timestamp_seconds{resource="${RESOURCE}"} $(date +%s)
EOF
```

| Variable | Description |
| -------- | ----------- |
| `GATEWAY` | The hostname/IP of the pushgateway to push to (check firewalls, stay within environment if possible) |
| `MAX_AGE` | The SLO value for alerting, in seconds. |
| `RESOURCE` | The resource identifier to include in alerts. Do not include data, that changes between invocations (such as pipeline or job IDs for example) |
| `TIER` | The tier of the monitored service (e.g. `db`) |
| `TYPE` | The tpye of the monitored service (e.g. `postgres`)

## Alerting

Any metric reporting created like above automatically has alerting enabled. These alerts will be sent out to s4.

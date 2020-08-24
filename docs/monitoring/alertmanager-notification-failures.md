# Alertmanager Notification Failures

## Symptoms

Alertmanager is getting errors trying to send alerts. Alerts will be
lost.

## Possible checks

Check the AlertManager logs to find out why it could not send alerts.
In the `gitlab-ops` project of Google Cloud, open the `Workloads` section under
the `Kubernetes Engine` section of the web console. Select the Alertmanager
workload, named `alertmanager-gitlab-monitoring-promethe-alertmanager`. Here
you can see details for the Alertmanager pods and select `Container logs`
to review the logs.

The AlertManager pod is very quiet except for errors so it should be quickly
obvious if it could not contact a service.

Note the "integration" label on the alert. If it's only one
integration it's probably a problem with the setup of that
integration.

For example if it's slack you can get the API key by looking for
"infra-automation app Slack API Token" in 1password.

And you can test it with curl

```
curl -X POST -H 'Content-type: application/json' \
 --data '{"text":"Ceci cest un test."}' \
 https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX
```

If it receives a 404 result then the channel does not exist. See [slack docs](https://api.slack.com/changelog/2016-05-17-changes-to-errors-for-incoming-webhooks) for other possible error codes.

For more information see https://api.slack.com/incoming-webhooks

## Troubleshooting which integration is failing

* In Prometheus, run this query: [`rate(alertmanager_notifications_failed_total[10m])`](https://prometheus.gprd.gitlab.net/graph?g0.range_input=1d&g0.expr=rate(alertmanager_notifications_failed_total%5B10m%5D)&g0.tab=0).
* This will give you a breakdown of which integration is failing, and from
  which server.
* For the slackline, you can view [the `alertManagerBridge` cloud function](https://console.cloud.google.com/functions/details/us-central1/alertManagerBridge?project=gitlab-infra-automation), [its logs](https://console.cloud.google.com/logs?service=cloudfunctions.googleapis.com&key1=alertManagerBridge&key2=us-central1&project=gitlab-infra-automation), and [code](https://gitlab.com/gitlab-com/gl-infra/slackline).
* Keep in mind that, if nothing has changed, the problem is likely to be on
  the remote side - for example, a Slack or Pagerduty issue.

## Manually review the currently open alerts

* Open the alert-manager UI: https://alerts.gitlab.net/
* Review each alert to check if it's notification has failed and whether
  further action is required.

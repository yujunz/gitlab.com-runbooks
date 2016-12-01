## How to create alerts in prometheus

Generally speaking alerts are triggered by prometheus, and then grouped, prioritized and deduped by the alert manager.

### General guidelines

In order to create new alerts they have to be included in the alerts folder in this repository.

The common procedure is as follows:

1. Create or reuse an alert rules file in [runbooks alerts directory](https://gitlab.com/gitlab-com/runbooks/tree/master/alerts).
1. Consider creating a runbook for the alert in the [runbooks project](https://gitlab.com/gitlab-com/runbooks). After mirroring runbook should appear in `https://dev.gitlab.com/cookbooks/runbooks` project. All urls will be constructed with the prefix - `https://dev.gitlab.com/cookbooks/runbooks/blob/master/`. Remain part should be annotated in `runbook` value.
1. Make sure that the alert title/summary is clear and actionable. Avoid alerting for "Worker load is critical" because that does not provide any action or enough information to know where to look, rather alert on "High load on worker due to increased IOWait" or "High number of queued jobs in sidekiq"
1. Consider adding a description to the alert with some context, you could also point to relevant graphs or provide quick actions.
1. Point the runbook link to dev.gitlab.org and make sure that it is available there, when GitLab.com is down you will not be able to get the runbook from there.
1. If the alert will be triggered throught Slack, consider adding `@channel` to the message to bring attention.

### Sample alert

```
## ALERT WHEN THE RUNNERS CACHE IS DOWN FOR MORE THAN 10 SECONDS
ALERT runners_cache_is_down
  IF probe_success{job="runners-cache", instance="localhost:9100"} == 0
  FOR 10s
  LABELS {severity="critical", channel="infrastructure", pager="pagerduty"}
  ANNOTATIONS {
    title="Runners cache has been down for the past 10 seconds",
    runbook="howto/howto/manage-cehpfs.md"
    description="This impacts CI execution builds, consider tweeting: !tweet 'CI executions are being delayed due to our runners cache being down at GitLab.com, we are investigating the root cause'"
  }
```

This will result in a critical alert posted in slack channes `#prometheus-alerts` and `#infrastructure`, pagerduty with a link to https://dev.gitlab.com/cookbooks/runbooks/blob/master/howto/manage-cehpfs.md. Important part is the end or url - `howto/manage-cehpfs.md`. It is taken from annotation `runbook`. Runbook will provide information how to manage situation alerted. Main principle of the runbook should be - `don't make me think`.

### What if I want to add more data?

You can use prometheus labels data by adding them into the text like this:

```
...
    description="Current response time is {{$value}} seconds for host {{$labels.instance}}"
...
```

That way you provide much more context in a single message.

### Alert routing

All alerts are routed to slack and additionally can be paged to PagerDuty.

### Sending to the Slack Pager

1. Since all alerts sended to slack, you can control only the type of alert.
1. All alerts will be shown in `#prometheus-alerts` channel.
1. Additionally you can send alerts to `#ci`, `#infrastructure` channels. This part controlled with the label `channel='ci'` and `channel='infrastructure'`.
1. Alerts with `severity=critical` are red colored messages with `.title` and link to corresponding runbook and `.description` values from alert.
1. Alerts with `severity=warn` are yellow colored messages with `.title` and link to corresponding runbook and `.description` values from alert.
1. Alerts with `severity=info` are green colored messages with `.title` and link to corresponding runbook and `.description` values from alert.
1. When the critical or warning alert is resolved, a green colored message with same title will be placed in channel. Prefix will be `[RESOLVED]`.

### Sending to the Pagerduty Pager

1. In order to get alerts in pagerduty, label `pager=pagerduty` should be applied during alert activation.
1. Pagerduty will receive message with description from `.title` and runbook link.
1. Pagerduty will then page whoever is on call at that time.
1. Alertmanager takes care of resolving issue in PagerDuty if alert is resolved.

### Email rules

Currently we are not using email alerting rules.

### Note about alerts which not fit in any routes

1. Alerts which are routed by default route will be sent to `#prometheus-alerts` channel in slack.
1. These alerts will prepend the text `following alert not processed`.
1. If you see such alerts, it means that there is problem with the routes in alertmanager config or severity label is not applied to alert.

![Unknown alert](../img/default_routed_alert.png)

## References

* [Prometheus template source code](https://github.com/prometheus/prometheus/blob/master/template/template.go#L115)
* [Prometheus default alert manager expansion template](https://github.com/prometheus/alertmanager/blob/master/template/default.tmpl)

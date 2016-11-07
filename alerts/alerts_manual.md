## Manual

Generally speaking alerts are triggered by prometheus, and then grouped, prioritized and deduped by the alert manager.

### General guidelines

In order to create new alerts they have to be included in the gitlab-prometheus cookbook and they need to be pushed to the prometheus instance.

The common path is as follows:

1. Create or reuse an alert rules file in [gitlab-prometheus](https://gitlab.com/gitlab-cookbooks/gitlab-prometheus/) repository as an erb template.
1. If it's not there already, add the filename to alert rules files list in `attributes/prometheus.rb` file, inside `default[:prometheus][:rules]` array.
1. Consider creating a runbook for the alert in the [runbooks project](https://gitlab.com/gitlab-com/runbooks) inside the alerts folder. This is so because the AlertManager is setup to build the title URL like `https://dev.gitlab.org/.../alerts/<alert_title>.md`
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
  LABELS {severity="critical, pager="slack", pager="pagerduty"}
  ANNOTATIONS {
    summary="Runners cache has been down for the past 10 seconds"
    description="This impacts CI execution builds, consider tweeting: !tweet 'CI executions are being delayed due to our runners cache being down at GitLab.com, we are investigating the root cause'"
  }
```

This will result in a critical alert posted both to slack and pagerduty with a link to https://dev.gitlab.com/cookbooks/runbooks/blob/master/alerts/runners_cache_is_down.md and providing the command to run from the infrastructure channel to manage outside communications out of the box - don't make me think.


### Alert routing

Alerts can be routed to none, one or many pagers. Currently we have at least 2 pagers: slack and pagerdury, both have different meaning and behavior.

### Sending to the Slack Pager

1. In order to get alert in slack, labels `pager=slack` and `severity=critical` should be applied during alert activation.
1. Message will be triggered in `#prometheus-alerts` channel. It is red colored message with `.title` and link to corresponding runbook.
1. When the alert is  resolved, a green colored message with same title will be placed in channel.

### Sending to the Pagerduty Pager

1. In order to get alerts in pagerduty, labels `pager=pagerduty` should be applied during alert activation, no need to add _critical_ to it.
1. Pagerduty will receive message with description from `.title` and runbook link.
1. Pagerduty will then page whoever is on call at that time.

### Email rules

Currently we are not using email alerting rules.

### Note about alerts which not fit in any routes

1. Alerts which are routed by default route will be sent to `#prometheus-alerts` channel in slack.
1. These alerts will prepend the text `following alert not processed`.

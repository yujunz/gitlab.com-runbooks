## Manual

### General rules

1. Create alert rules file in [gitlab-prometheus](https://gitlab.com/gitlab-cookbooks/gitlab-prometheus/) repository.
1. Add it to alert rules files list of prometheus - `attributes/prometheus.rb` file, `default[:prometheus][:rules]` array.
1. Create runbook for alert in [runbooks project](https://gitlab.com/gitlab-com/runbooks) in folder `alert`. Name of your file must be same as `alert` name with `.md` extension.
1. Title for message will be taken from annotation `title`.
1. If runbook url is placed somewhere in alert, then it is must be constructed as `https://dev.gitlab.org/cookbooks/runbooks/blob/master/alerts/<alertname>.md`.

### Slack related rules

1. In order to get alert in slack, labels `pager=slack` and `severity=critical` should be applied during alert activation.
1. Message will be placed in `#prometheus-alerts` channel. It is red colored message with `.title` and link to corresponding runbook.
1. When condition resolved, green colored message with corresponding title will be placed in channel.

### Pagerduty related rules

1. In order to get alerts in pagerduty, labels `pager=pagerduty` should be applied during alert activation.
1. Pagerduty will receive message with description from `.title` and runbook link.

### Email rules

### Note about alerts which not fit in any routes

1. Alerts which are routed by default route will be sent to `#prometheus-alerts` channel in slack.
1. Alerts will have `following alert not processed` pretext.

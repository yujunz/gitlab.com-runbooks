### Manual

1. Create alert rules file in [gitlab-prometheus](https://gitlab.com/gitlab-cookbooks/gitlab-prometheus/) repository.
1. Add it to alert rules files list of prometheus - `attributes/prometheus.rb` file, `default[:prometheus][:rules]` array.
1. Create runbook for alert in [runbooks project](https://gitlab.com/gitlab-com/runbooks) in folder `alert`. Name of your file must be same as `alert` name.
1. Title for message will be taken from annotation `title` and text will be taken from annotation `text`.
1. If you want to send alert as error with the link to the runbook, you have to specify additionally `pager=slack_critical` label. In that case message in slack will be red.
1. If alert will be informational or resolving, you have to specify `pager=slack_ok` label. In that case message in slack will be green.
1. If message must be notified via pagerdury, add `pager=pagerdury` label.

## GitLab monitoring

### General overview

![Logical scheme](../img/gitlab-monitoring.png)

[draw.io source](../graphs/gitlab-monitoring.xml) for later modifications.


GitLab monitoring consist of the following parts:

1. 3 prometheus instances - 2 for HA, 1 for public monitoring. Each has role `prometheus-server` in chef, which specifies which metrics to collect.
1. 2 alertmanager instances - each of alertmanagers connected to corresponding prometheus instance and alert about availability of prometheus servers (each) and other other specified [alerting rules](https://dev.gitlab.org/cookbooks/runbooks/tree/master/alerts) (only on prometheus.gitlab.com). Effective roles in chef for alertmanagers are - `prometheus-alertmanager`, `prometheus-gitlab-com-monitoring`, `prometheus-2-gitlab-com-monitoring`.
1. 1 haproxy instance - this is used for providing metrics for grafana in the case when one of the prometheus instances is down. Role in chef - `prometheus-haproxy`. So keeping prometheus instances collecting (scraping) metrics permanently is main thing to take care of.
1. 2 grafana instances - 1 for internal usage, 1 for public monitoring. Public grafana instance provides all dashboards tagged `public` from Internal one. (*TO BE COMPLETED HERE*)

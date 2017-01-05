## GitLab monitoring

### General overview

[Logical scheme](../img/gitlab-monitoring.png)

GitLab monitoring consist of the following parts:

1. 3 prometheus instances - 2 for HA, 1 for public monitoring. Each has role `prometheus-server` in chef, which specifies which metrics to collect.
1. 2 alertmanager instances - each of alertmanagers connected to corresponding prometheus instance and alert about availability of prometheus servers (each) and other other specified [alerting rules](https://dev.gitlab.org/cookbooks/runbooks/tree/master/alerts) (only on prometheus.gitlab.com). Effective roles in chef for alertmanagers are - `prometheus-alertmanager`, `prometheus-gitlab-com-monitoring`, prometheus-2-gitlab-com-monitoring`.
1. 2 grafana instances - 1 for internal usage, 1 for public monitoring. Public grafana instance provides all dashboards tagged `public` from Internal one. (*TO BE COMPLETED HERE*)

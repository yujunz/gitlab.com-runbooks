## GitLab monitoring

### General overview

![Logical scheme](img/gitlab-monitoring.png)

[draw.io source](../../graphs/gitlab-monitoring.xml) for later modifications.

[video: delivery: intro to monitoring at gitlab.com](https://www.youtube.com/watch?reload=9&v=fDeeYqCnuoM&list=PL05JrBw4t0KoPzC03-4yXuJEWdUo7VZfX&index=13&t=0s)

[epic about figuring out and documenting monitoring](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/75)

[video: General metrics and anomaly detection](https://www.youtube.com/watch?reload=9&v=Oq5PHtgEM1g&feature=youtu.be)


GitLab monitoring consist of the following parts:

1. 3 prometheus instances - 2 for HA, 1 for public monitoring. Each has role `prometheus-server` in chef, which specifies which metrics to collect.
1. 2 alertmanager instances - each of alertmanagers connected to corresponding prometheus instance and alert about availability of prometheus servers (each) and other other specified [alerting rules](https://dev.gitlab.org/cookbooks/runbooks/tree/master/alerts) (only on prometheus.gitlab.com). Effective roles in chef for alertmanagers are - `prometheus-alertmanager`, `prometheus-gitlab-com-monitoring`, `prometheus-2-gitlab-com-monitoring`.
1. 1 haproxy instance - this is used for providing metrics for grafana in the case when one of the prometheus instances is down. Role in chef - `prometheus-haproxy`. So keeping prometheus instances collecting (scraping) metrics permanently is main thing to take care of.
1. 2 grafana instances - 1 for internal usage, 1 for public monitoring. Public grafana instance provides all dashboards tagged `public` from Internal one. (*TO BE COMPLETED HERE*)

Grafana dashboards on dashboards.gitlab.net are managed in 3 ways:

1. By hand, editing directly using the Grafana UI
1. Uploaded from https://gitlab.com/gitlab-com/runbooks/tree/master/dashboards, either:
   1. json - literally exported from grafana by hand, and added to that repo
   1. jsonnet - JSON generated using jsonnet/grafonnet; see https://gitlab.com/gitlab-com/runbooks/blob/master/dashboards/README.md

All dashbaords are downloaded/saved automatically into https://gitlab.com/gitlab-org/grafana-dashboards, in the dashboards directory.
This happens from the gitlab-grafan:export_dashboards recipe, which runs some Ruby/chef code at every *chef run* on the *public* dashboards server, pulling from the pulling from the *private* dashboards server and then committing any changes to the git repository.  The repo is also mirror to https://ops.gitlab.net/gitlab-org/grafana-dashboards

Grafana dashboards on dashboards.gitlab.com are synced from dashboards.gitlab.net every 5 minutes by a script (/usr/local/sbin/sync_grafana_dashboards) run by cron every 5 minutes on the public grafana server (dashboards-com-01-inf-ops.c.gitlab-ops.internal).

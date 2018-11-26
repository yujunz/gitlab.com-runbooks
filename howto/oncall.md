# So you got yourself on call

To start with the right foot let's define a set of tasks that are nice things to do before you go
any further in your week

By performing these tasks we will keep the [broken window
effect](https://en.wikipedia.org/wiki/Broken_windows_theory) under control, preventing future pain
and mess.

## Things to keep an eye on

### On-call issues

First check [the on-call issues][on-call-issues] to familiarize yourself with what has been
happening lately. Also, keep an eye on the [#production][slack-production] and
[#incident-management][slack-incident-management] channels for discussion around any on-going
issues.

### Alerts

Start by checking how many alerts are in flight right now

-   go to the [fleet overview dashboard](https://dashboards.gitlab.net/dashboard/db/fleet-overview) and check the number of Active Alerts, it should be 0. If it is not 0
    -   go to the alerts dashboard and check what is being triggered
        -   [azure][prometheus-azure]
        -   [gprd prometheus][prometheus-gprd]
        -   [gprd prometheus-app][prometheus-app-gprd]
    -   watch the [#alerts][slack-alerts], [#alerts-general][slack-alerts-general], and [#alerts-gstg][slack-alerts-gstg] channels for alert notifications; each alert here should point you to the right [runbook][runbook-repo] to fix it.
    -   if they don't, you have more work to do.
    -   be sure to create an issue, particularly to declare toil so we can work on it and suppress it.

### Prometheus targets down

Check how many targets are not scraped at the moment. alerts are in flight right now, to do this:

-   go to the [fleet overview dashboard](https://dashboards.gitlab.net/dashboard/db/fleet-overview) and check the number of Targets down. It should be 0. If it is not 0
    -   go to the [targets down list] and check what is.
        -   [azure][prometheus-azure-targets-down]
        -   [gprd prometheus][prometheus-gprd-targets-down]
        -   [gprd prometheus-app][prometheus-app-gprd-targets-down]
    -   try to figure out why there is scraping problems and try to fix it. Note that sometimes there can be temporary scraping problems because of exporter errors.
    -   be sure to create an issue, particularly to declare toil so we can work on it and suppress it.

## Rotation Schedule

We use [PagerDuty](https://gitlab.pagerduty.com) to manage our on-call rotation schedule and
alerting for emergency issues. We currently have a split schedule between EMEA and AMER for on-call
rotations in each geographical region; we will also incorporate a rotation for team members in the
APAC region as we continue to grow over time.

The [EMEA][pagerduty-emea] and [AMER][pagerduty-amer] schedule [each have][pagerduty-emea-shadow] a
[shadow schedule][pagerduty-amer-shadow] which we use for on-boarding new engineers to the on-call
rotations.

When a new engineer joins the team and is ready to start shadowing for an on-call rotation,
[overrides][pagerduty-overrides] should be enabled for the relevant on-call hours during that
rotation. Once they have completed shadowing and are comfortable/ready to be inserted into the
primary rotations, update the membership list for the appropriate schedule to [add the new team
member][pagerduty-add-user].

This [pagerduty forum post][pagerduty-shadow-schedule] was referenced when setting up the [blank
shadow schedule][pagerduty-blank-schedule] and initial [overrides][pagerduty-overrides] for
on-boarding new team members.


[on-call-issues]:                   https://gitlab.com/gitlab-com/infrastructure/issues?scope=all&utf8=%E2%9C%93&state=all&label_name[]=oncall

[pagerduty-add-user]:               https://support.pagerduty.com/docs/editing-schedules#section-adding-users
[pagerduty-amer]:                   https://gitlab.pagerduty.com/schedules#PKN8L5Q
[pagerduty-amer-shadow]:            https://gitlab.pagerduty.com/schedules#P0HRY7O
[pagerduty-blank-schedule]:         https://community.pagerduty.com/t/creating-a-blank-schedule/212
[pagerduty-emea]:                   https://gitlab.pagerduty.com/schedules#PWDTHYI
[pagerduty-emea-shadow]:            https://gitlab.pagerduty.com/schedules#PSWRHSH
[pagerduty-overrides]:              https://support.pagerduty.com/docs/editing-schedules#section-create-and-delete-overrides
[pagerduty-shadow-schedule]:        https://community.pagerduty.com/t/creating-a-shadow-schedule-to-onboard-new-employees/214

[prometheus-azure]:                 https://prometheus.gitlab.com/alerts
[prometheus-azure-targets-down]:    https://prometheus.gitlab.com/consoles/up.html
[prometheus-gprd]:                  https://prometheus.gprd.gitlab.net/alerts
[prometheus-gprd-targets-down]:     https://prometheus.gprd.gitlab.net/consoles/up.html
[prometheus-app-gprd]:              https://prometheus-app.gprdgitlab.net/alerts
[prometheus-app-gprd-targets-down]: https://prometheus-app.gprd.gitlab.net/consoles/up.html

[runbook-repo]:                     https://gitlab.com/gitlab-com/runbooks

[slack-alerts]:                     https://gitlab.slack.com/channels/alerts
[slack-alerts-general]:             https://gitlab.slack.com/channels/alerts-general
[slack-alerts-gstg]:                https://gitlab.slack.com/channels/alerts-gstg
[slack-incident-management]:        https://gitlab.slack.com/channels/incident-management
[slack-production]:                 https://gitlab.slack.com/channels/production

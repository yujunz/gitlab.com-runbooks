# Engineer On Call (EOC)

To start with the right foot let's define a set of tasks that are nice things to do before you go
any further in your week

By performing these tasks we will keep the [broken window
effect](https://en.wikipedia.org/wiki/Broken_windows_theory) under control, preventing future pain
and mess.

## Going on call

Here is a suggested checklist of things to do at the start of an on-call shift:

- *Change Slack Icon*: Click name. Click `Set status`. Click grey smile face. Type `:pagerduty:`. Set `Clear after` to end of on-call shift. Click `Save`
- *Join alert channels*: If not already a member, `/join` `#alerts`, `#alerts-general`, `#alerts-prod-abuse`, `#tenable-notifications`, `#marquee_account_alrts`
- *Turn on slack channel notifications*: Open `#production` and `#incident-management` Notification Preferences (and optionally #infrastructure-lounge). Set Desktop and Mobile to `All new messages`
- *Turn on slack alert notifications*: Open `#alerts` and `#alerts-general`, Notification Preferences. Set Desktop only to `All new messages`
- At the start of each on-call day, read the on-call handover issue that has
  been assigned to you by the previous EOC, and familiarize yourself with any
  ongoing incidents.

At the end of a shift:

- *Turn off slack channel notifications*: Open notification preferences in monitored Slack channels from the previous checklist and return alerts to the desired values.
- *Leave noisy alert channels*: `/leave` alert channels (It's good to stay in `#alerts` and `#alerts-general`)
- Comment on any open S1 incidents at: https://gitlab.com/gitlab-com/gl-infra/production/issues?scope=all&utf8=✓&state=opened&label_name%5B%5D=incident&label_name%5B%5D=S1
- At the end of each on-call day, post a quick update in slack so the next person is aware of anything ongoing, any false alerts, or anything that needs to be handed over.

## Things to keep an eye on

### On-call issues

First check [the on-call issues][on-call-issues] to familiarize yourself with what has been
happening lately. Also, keep an eye on the [#production][slack-production] and
[#incident-management][slack-incident-management] channels for discussion around any on-going
issues.

### Useful Dashboard to keep open

- [GitLab Triage](https://dashboards.gitlab.net/d/RZmbBr7mk/gitlab-triage?orgId=1&refresh=30s)

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
[prometheus-app-gprd]:              https://prometheus-app.gprd.gitlab.net/alerts
[prometheus-app-gprd-targets-down]: https://prometheus-app.gprd.gitlab.net/consoles/up.html

[runbook-repo]:                     https://gitlab.com/gitlab-com/runbooks

[slack-alerts]:                     https://gitlab.slack.com/channels/alerts
[slack-alerts-general]:             https://gitlab.slack.com/channels/alerts-general
[slack-alerts-gstg]:                https://gitlab.slack.com/channels/alerts-gstg
[slack-incident-management]:        https://gitlab.slack.com/channels/incident-management
[slack-production]:                 https://gitlab.slack.com/channels/production

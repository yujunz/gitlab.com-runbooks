# So you got yourself on call

To start with the rigth foot let's define a set of tasks that are nice things to do before you go any further in your week

By performing these tasks we will keep the [broken window effect](https://en.wikipedia.org/wiki/Broken_windows_theory) under control, preventing future pain and mess.

## Things to keep an eye on

### On-call log

First check [the on-call log](https://docs.google.com/document/d/1nWDqjzBwzYecn9Dcl4hy1s4MLng_uMq-8yGRMxtgK6M/edit#heading=h.nmt24c52ggf5) to familiarize yourself with what has been hapening lately, if anything is on fire it should be written down there in the **Pending actions** section

### Alerts

Start by checking how many alerts are in flight right now, to do this:

- go to the [fleet overview dashboard](https://performance.gitlab.net/dashboard/db/fleet-overview) and check the number of Active Alerts, it should be 0. If it is not 0
  - go to the alerts dashboard and check what is [being triggered](https://prometheus.gitlab.com/alerts) each alert here should point you to the right runbook to fix it.
  - if they don't, you have more work to do.
  - be sure to create an issue, particularly to declare toil so we can work on it and suppress it.

### Nodes status

Go to your chef repo and run `knife status`, if you see hosts that are red it means that chef hasn't been running there for a long time. Check in the oncall log if they are disabled for any particular reason, if they are not, and there is no mention of any ongoing issue in the on-call log, consider jumping in to check why chef has not been running there.

### Prometheus targets down

Check how many targets are not scraped at the moment. alerts are in flight right now, to do this:

- go to the [fleet overview dashboard](https://performance.gitlab.net/dashboard/db/fleet-overview) and check the number of Targets down. It should be 0. If it is not 0
  - go to the [targets down list](https://prometheus.gitlab.com/consoles/up.html) and check what is.
  - try to figure out why there is scraping problems and try to fix it. Note that sometimes there can be temporary scraping problems because of exporter errors.
  - be sure to create an issue, particularly to declare toil so we can work on it and suppress it.

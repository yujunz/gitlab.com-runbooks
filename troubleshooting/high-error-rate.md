# Increased Error Rate

## First and foremost

*Don't Panic*

## Symptoms

* Message in prometheus-alerts _Increased Error Rate Across Fleet_

## Troubleshoot
- Check the [triage overview](https://performance.gitlab.net/dashboard/db/triage-overview) dashboard for 5xx errors by backend.
- Check [Sentry](https://sentry.gitlap.com/gitlab/gitlabcom/) for new 500 errors.
- If the problem persists send a channel wide notification in `#development`.

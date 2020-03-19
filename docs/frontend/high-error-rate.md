# Increased Error Rate

## Symptoms

- Message in prometheus-alerts _Increased Error Rate Across Fleet_
- PagerDuty Alert: _HighRailsErrorRate_

## Troubleshoot
### Kibana
  - [All 5xx statuses in rails](https://log.gprd.gitlab.net/goto/c0d8ed2d964e4a792838e77a4ac1f942)
  - [All 5xx statuses by controller](https://log.gprd.gitlab.net/goto/19bccd903f408085535df92734176cec)
  - [Check for abuse from a specific IP](https://log.gprd.gitlab.net/goto/d4c6a0d68a565a0ac70b3840306f8eca)
- Check the [triage overview](https://dashboards.gitlab.net/d/RZmbBr7mk/gitlab-triage) dashboard for 5xx errors by backend.
- Check [Sentry](https://sentry.gitlab.net/gitlab/gitlabcom/) for new 500 errors or an uptick.
- If the problem persists send a channel wide notification in [#development](https://gitlab.slack.com/archives/development).

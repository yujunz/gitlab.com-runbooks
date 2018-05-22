# Database Incidents

Below is a checklist to use for responding to database incidents that affect
GitLab.com. To use this checklist, create an issue in the [infrastructure
tracker][new-infra-issue] using the "database_incident.md" issue template. If
GitLab.com is not available, use the [organization project on
dev.gitlab.org][new-dev-issue]. When doing so, make sure to copy the issue to
the GitLab.com infrastructure tracker once GitLab.com is back online, then keep
that issue up-to-date _instead_ of the issue on dev.gitlab.org. This ensures all
progress/information is in one spot, instead of being spread across the two
different instances.

The title for incident issues should be in the following format:

    YYYY-MM-DD: Incident title

Each incident issue should have the following labels:

* ~database
* ~outage, or ~degradation (depending on the type of outage)

You can [create a new issue with the right template by clicking this
link](https://gitlab.com/gitlab-com/infrastructure/issues/new?issuable_template=database_incident).

[new-infra-issue]: https://gitlab.com/gitlab-com/infrastructure/issues/new
[new-dev-issue]: https://dev.gitlab.org/gitlab/organization/issues/new

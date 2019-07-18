# Pull mirror overdue queue is too large

## First and foremost

*Don't Panic*

## Symptoms

* Message in #alerts-gprd: _Large number of overdue pull mirror jobs_

## Background

Mirroring repositories is executed as follows:

1. Sidekiq runs a `UpdateAllMirrorsWorker` job every minute
1. `UpdateAllMirrorsWorker` schedules `ProjectImportScheduleWorker` jobs in bulks, the number depends on the available mirroring capacity
    * In other words, each minute we schedule a number of `ProjectImportScheduleWorker` jobs equal to the available mirroring capacity
1. Each `ProjectImportScheduleWorker` job schedules a `RepositoryUpdateMirrorWorker`, in which the actual mirroring happens
1. When `RepositoryUpdateMirrorWorker` runs, it adds the project ID to a Redis set, when it finishes (or fails), it removes the project ID from the set.
    * That's how we track the available mirroring capacity; which equals [maximum mirroring capacity][maximum-mirroring-capacity] - number of project IDs in the set

As GitLab.com grows, the number of mirrored project is going to grow as well. We may need to adjust mirroring capacity accordingly.

## Troubleshoot

1. View the [pull mirror dashboard](https://dashboards.gitlab.net/d/_MKRXrSmk/pull-mirrors).
1. View the [Sidekiq Queue size graph][sidekiq-queue-sizes].
1. This alert may just be a symptom of slow Sidekiq jobs. If there are many jobs in the queue (i.e. over 10,000 and growing),
   you may want to [investigate the state of PgBouncer](pgbouncer.md).
1. Under "Running Jobs", pay attention to the `UpdateAllMirrorsWorker`. If that has gone flat, then
you may need to log the state of the pending pull mirror queue.
1. Check [Sentry](https://sentry.gitlab.net/gitlab/gitlabcom/) for new 500 errors relating to `UpdateAllMirrorsWorker`.
1. Check if Redis cpu usage is high using [the redis dashboard](https://dashboards.gitlab.net/d/wccEP9Imk/redis?orgId=1&refresh=1m). If it is, the sidekiq slow down is likely related to [this issue](https://gitlab.com/gitlab-com/gl-infra/production/issues/937). Follow the instructions in [this
   snippet](https://gitlab.com/gitlab-com/gl-infra/infrastructure/snippets/1873154)
   to aggressively enqueue pull mirror jobs. This will continue to be necessary
   until a long-term solution is implemented.

[maximum-mirroring-capacity]: https://gitlab.com/admin/application_settings/repository#js-mirror-settings
[sidekiq-queue-sizes]: https://dashboards.gitlab.net/d/9GOIu9Siz/sidekiq-stats?orgId=1&panelId=3&fullscreen

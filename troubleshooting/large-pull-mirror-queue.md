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

1. View the [Sidekiq Queue size graph][sidekiq-queue-sizes].
1. This alert may just be a symptom of slow Sidekiq jobs. If there are many jobs in the queue (i.e. over 10,000 and growing),
   you may want to [investigate the state of PgBouncer](pgbouncer.md).
1. View the [pull mirror dashboard](https://dashboards.gitlab.net/d/_MKRXrSmk/pull-mirrors).
1. In a Rails console run:

    ```ruby
    # Maximum number of overdue mirrors per minute
    # SLOW QUERY! Run in postgres-dr-archvie
    Project.mirror.joins_import_state.group("date_trunc('minute', next_execution_timestamp)").count.values.max
    ```

   Compare the value to [maximum mirroring capacity][maximum-mirroring-capacity], if the difference is big (e.g. 1K or more), consider bumping the maximum
   capacity.
    * **Caution:** Bumping the capacity too high may put Redis and Sidekiq under stress. Bump in small increments and evaluate.

1. Under "Running Jobs", pay attention to the `UpdateAllMirrorsWorker`. If that has gone flat, then
you may need to log the state of the pending pull mirror queue.
1. Check [Sentry](https://sentry.gitlab.net/gitlab/gitlabcom/) for new 500 errors relating to `UpdateAllMirrorsWorker`.
1. Get the state of the Redis queue that holds which project IDs should be processed. In a Rails console run:

    ```ruby
    projects = Gitlab::Redis::SharedState.with { |redis| redis.smembers(Gitlab::Mirror::PULL_CAPACITY_KEY) }
    states = ProjectImportState.where(project_id: projects).order(:last_update_started_at).map(&:last_error)
    ```

1. If necessary, clear this set:

    ```ruby
    Gitlab::Redis::SharedState.with { |redis| redis.del(Gitlab::Mirror::PULL_CAPACITY_KEY) }
    ````

1. If the problem persists send a channel wide notification in `#backend`.

[maximum-mirroring-capacity]: https://gitlab.com/admin/application_settings/repository#js-mirror-settings
[sidekiq-queue-sizes]: https://dashboards.gitlab.net/d/9GOIu9Siz/sidekiq-stats?orgId=1&panelId=3&fullscreen

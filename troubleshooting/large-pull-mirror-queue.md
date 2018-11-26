# Pull mirror overdue queue is too large

## First and foremost

*Don't Panic*

## Symptoms

* Message in #alerts-gprd: _Large number of overdue pull mirror jobs_

## Troubleshoot

1. View the [pull mirror dashboard](https://dashboards.gitlab.net/d/_MKRXrSmk/pull-mirrors).
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

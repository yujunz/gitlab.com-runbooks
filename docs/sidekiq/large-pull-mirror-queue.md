# Pull mirror overdue queue is too large

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

1. View the [repository_update_mirror dashboard](https://dashboards.gitlab.net/d/sidekiq-queue-detail/sidekiq-queue-detail?var-queue=repository_update_mirror)
1. View the [catchall dashboard](https://dashboards.gitlab.net/d/sidekiq-shard-detail/sidekiq-shard-detail?var-shard=catchall)
1. View the [Sidekiq Queue size graph][sidekiq-queue-sizes].
1. This alert may just be a symptom of slow Sidekiq jobs. If there are many jobs in the queue (i.e. over 10,000 and growing),
   you may want to [investigate the state of PgBouncer](../pgbouncer/pgbouncer.md).
1. Under "Running Jobs", pay attention to the `UpdateAllMirrorsWorker`. If that has gone flat, then
you may need to log the state of the pending pull mirror queue.
1. Check [Sentry](https://sentry.gitlab.net/gitlab/gitlabcom/) for new 500 errors relating to `UpdateAllMirrorsWorker`.
1. Check the [logs][mirror-worker-logs], to see if a big upstream (e.g. bitbucket.org, github.com) are down/returning errors
   Look for consistent hostnames, projects/repos, or errors; note that there is a low grade normal rate of failure here, so you're looking for outliers.
1. Check the top long-running jobs using the script below, it displays how many minutes they have been running and the project ID.
   Check the projects (i.e. `Project.find(id)`) for a common pattern (e.g. they belong to the same user/group, they reside on the same shard, their upstream is the same, ...).
   ```ruby
   jobs = []
   Sidekiq::Workers.new.each do |process, thread, msg|
     job = Sidekiq::Job.new(msg['payload'])
     jobs << [Time.now - Time.at(msg['run_at']), job] if msg['queue'] == 'repository_update_mirror'
   end
   jobs.sort_by { |(t, job)| t }.reverse.first(25).each do |(t, job)|
     puts "#{t / 60} | #{job.args}"
   end; nil
   ```

[maximum-mirroring-capacity]: https://gitlab.com/admin/application_settings/repository#js-mirror-settings
[sidekiq-queue-sizes]: https://dashboards.gitlab.net/d/sidekiq-main/sidekiq-overview?panelId=89&fullscreen&orgId=1
[mirror-worker-logs]: https://log.gprd.gitlab.net/app/kibana#/discover/c5bb8a20-a088-11ea-8617-2347010d3aab

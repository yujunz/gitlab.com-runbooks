# Sidekiq Queue Out of Control

When the filesystem or database has major issues, it is possible
for the sidekiq queues to grow out of control. If the queues don't appear
to be getting any better after resolving other issues, please follow
the resolution below.

It could also be possible that Sidekiq is just spending time jumping from one
queue to the next not actually doing any job at all.

It may also be abuse or over-zealous activity (particularly mailers, exports, or pipelines)

## Symptoms

Open the [Sidekiq dashboard](http://dashboards.gitlab.net/dashboard/db/sidekiq-stats)
and check the Sidekiq Queue Size Size gauge. If it is over 5k it should be red, which
means that at least we should be keeping an eye on it.
Particularly take a look at Sidekiq Enqueued Jobs to hint a trend, if the trend
is going up consider taking action.

## Data Gathering

Run the following command in order to get Sidekiq to output debug info to the log

```
kill -TTIN <sidekiq_pid>
```

Check in `/var/log/gitlab/sidekiq/current` for the output. Check for blocking
queries when backtraces above show that many threads are stuck in the database adapter.

If `kill -TTIN` fails to work due to high CPU usage, gather statistics from `perf`.

```
sudo perf record -p <sidekiq_pid>
```

Let that run for around 30 seconds and then check the report `sudo perf report`

## Resolution

### Mail queue

If the queue is all in `mailers` and is in the many tens to hundreds of thousands it is
possible we have a spam/junk issue problem.  If so, refer to the abuse team for assistance,
and also https://gitlab.com/gitlab-com/runbooks/snippets/1923045 for some spam-fighting
techniques we have used in the past to clean up.  This is in a private snippet so as not
to tip our hand to the miscreants.  Often shows up in our gitlab public projects but could
plausibly be in any other project as well.

### Other situations

Another way to deal with the large queue is to spin up more sidekiq worker
processes with fewer threads that specifically deal with troublesome queues.
Often, this is the `pipelines` and `project_cache` queues.

For this we use
[sidekiq-cluster](http://docs.gitlab.com/ee/administration/operations/extra_sidekiq_processes.html),
a command introduced in GitLab 8.15. This command can be used to start extra
Sidekiq processes that consume only a limited number of Sidekiq queues.

sidekiq-cluster is configured via Omnibus/Chef just like any other service. The
service is configured to run on all nodes with role `gitlab-cluster-worker`. The
setting name used in the role's JSON is called `sidekiq-cluster`.

The option you're most likely interested in is called `queue_groups`. This
array specifies how many processes to start, and which queues they should
consume. For example, say you want to start two processes that consume
`process_commit` and `post_receive` respectively. In this case you'd use the
following settings:

```json
"sidekiq-cluster": {
  "enable": true,
  "queue_groups": [
    "process_commit",
    "post_receive"
  ]
}
```

If a process should consume multiple queues you will have to separate them by a
comma. For example:

```json
"sidekiq-cluster": {
  "enable": true,
  "queue_groups": [
    "process_commit,post_receive"
  ]
}
```

This will start 1 process that consumes _both_ `process_commit` and
`post_receive`.

Once the settings have been applied you'll need to run `sudo chef-client` on all
the workers. The easiest way of doing this is to use `knife` in the Chef
repository:

```
bundle exec knife ssh -aipaddress 'role:gitlab-cluster-worker' 'sudo chef-client'
```

## Managing (getting and removing) sidekiq queues and queued jobs

### Get queues using admin interface

https://gitlab.com/admin/sidekiq/queues

### Get queue size using rails console

```
$ gitlab-rails console
> # Sidekiq::Queue.new("<sidekiq_queue_name>").size
> Sidekiq::Queue.new("pipeline_processing:build_queue").size
```

src: https://docs.gitlab.com/ee/administration/troubleshooting/sidekiq.html#view-the-queue-size

### Get enqueued jobs using rails console

```
# queue = Sidekiq::Queue.new("<queue_name>")
queue = Sidekiq::Queue.new("chaos:chaos_sleep")
queue.each do |job|
  puts job
end
```

src: https://docs.gitlab.com/ee/administration/troubleshooting/sidekiq.html#enumerate-all-enqueued-jobs

### Get queues using sq.rb script

[sq](https://gitlab.com/gitlab-com/runbooks/raw/master/docs/uncategorized/db_scripts/sq.rb) is a command-line tool that you can run to
assist you in viewing the state of Sidekiq and killing certain workers. To use it,
first download a copy:

```bash
$ curl -o /tmp/sq.rb https://gitlab.com/gitlab-com/runbooks/raw/master/docs/uncategorized/db_scripts/sq.rb
```

To display a breakdown of all the workers, run:

```bash
$ sudo gitlab-rails runner /tmp/sq.rb
```

### Remove all jobs from a queue

If you need to drop an entire queue (e.g. `expire_build_instance_artifacts`):

1. Visit https://gitlab.com/admin/sidekiq/queues
2. Find the queue you want to drop and click "Delete"

Dropped queues will be automatically recreated as needed.

### Remove a specific worker that's pulling jobs from a shared queue

In GitLab, it's possible that there are multiple workers that share the same
Sidekiq queue. If you do not want to drop the entire queue and only specific
types of workers, you can do this via a command-line tool.

Suppose you see a lot of `RepositoryMirrorUpdateWorker` instances that you want to kill.
BE CAREFUL WITH THIS COMMAND! You can see how many jobs would be killed using the `--dry-run`
parameter:

```bash
$ curl -o /tmp/sq.rb https://gitlab.com/gitlab-com/runbooks/raw/master/docs/uncategorized/db_scripts/sq.rb
$ sudo gitlab-rails runner /tmp/sq.rb
$ sudo gitlab-rails runner /tmp/sq.rb kill <WORKER NAME> --dry-run
```

For example:

```bash
$ sudo gitlab-rails runner /tmp/sq.rb kill RepositoryMirrorUpdateWorker --dry-run
```

You can omit the `--dry-run` option if you want to remove the jobs.
Putting the script in `/tmp` is one way of making sure its readable by `git` user
with default umask setting. Otherwise rails console will treat the path as
Ruby string and [most likely err](https://github.com/rails/rails/blob/v4.2.8/railties/lib/rails/commands/runner.rb#L58-L63).

### Remove jobs with certain metadata from a queue (e.g. all jobs from a certain user)

We currently track metadata in sidekiq jobs, this allows us to remove
sidekiq jobs based on that metadata.

Interesting attributes to remove jobs from a queue are `root_namespace`,
`project` and `user`. The [admin Sidekiq queues
API](https://docs.gitlab.com/ee/api/admin_sidekiq_queues.html) can be
used to remove jobs from queues based on these medata values.

For instance:

```shell
$ curl --request DELETE --header "Private-Token: $GITLAB_API_TOKEN_ADMIN" https://gitlab.com/api/v4/admin/sidekiq/queues/post_receive?user=reprazent&project=gitlab-org/gitlab
```

Will delete all jobs from `post_receive` triggered by a user with
username `reprazent` for the project `gitlab-org/gitlab`.

This API endpoint is bound by the HTTP request time limit, so it will
delete as many jobs as it can before terminating. If the `completed` key
in the response is `false`, then the whole queue was not processed, so
we can try again with the same command to remove further jobs.

## Killing running sidekiq jobs (specific type, specific user)

THIS PROCEDURE WAS NOT TESTED IN PRODUCTION!!!!!!!!!!

This is a highly risky operation and use it as a last resort. Doing this might result in data corruption, as the job is interrupted mid-execution and it is not guaranteed that proper rollback of transactions is implemented.

Here's an example of how to get all jobs of one type, from one user and how to kill them:
```ruby
queue_types = ["project_export"]
username = ["blahblahputusernamehere"]
# get an object holding references to all running jobs, see sidekiq docs for more info
workers = Sidekiq::Workers.new
all_jobs_of_type = workers.to_enum(:each).select { |pid, tid, work| queue_types.include?(work["queue"]) }
users_jobs = all_jobs_of_type.to_enum(:each).select { |pid, tid, work| username.include?(work["payload"]["meta.user"]) }
users_jobs.each { |pid, tid, work| puts "Killing job with jid: #{work["payload"]["jid"]}"; Gitlab::SidekiqDaemon::Monitor.cancel_job(work["payload"]["jid"])  }
```

src: https://docs.gitlab.com/ee/administration/troubleshooting/sidekiq.html#canceling-running-jobs-destructive

## References

* https://gitlab.com/gitlab-com/infrastructure/issues/677
* https://gitlab.com/gitlab-com/infrastructure/issues/606
* https://gitlab.com/gitlab-com/infrastructure/issues/584
* https://docs.gitlab.com/ee/administration/troubleshooting/sidekiq.html

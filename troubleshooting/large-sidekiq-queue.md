# Sidekiq Queue Out of Control

When the filesystem or database has major issues, it is possible
for the sidekiq queues to grow out of control. If the queues don't appear
to be getting any better after resolving other issues, please follow
the resolution below.

It could also be possible that Sidekiq is just spending time jumping from one
queue to the next not actually doing any job at all.

## First and foremost

*Don't Panic*

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

The best way to deal with the large queue is to spin up more sidekiq worker
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

## Viewing and killing jobs from the queue

[sq](https://gitlab.com/gitlab-com/runbooks/raw/master/troubleshooting/db_scripts/sq.rb) is a command-line tool that you can run to
assist you in viewing the state of Sidekiq and killing certain workers. To use it,
first download a copy:

```
curl -o sq.rb https://gitlab.com/gitlab-com/runbooks/raw/master/troubleshooting/db_scripts/sq.rb
```

To display a breakdown of all the workers, run:

```
sudo gitlab-rails runner $PWD/sq.rb
```

### Killing jobs

There are two ways of killing jobs:

1. Via the Sidekiq admin page: https://gitlab.com/admin/sidekiq/queues
2. Via the command-line

## Dropping an entire queue

If you need to drop an entire queue (e.g. `expire_build_instance_artifacts`):

1. Visit https://gitlab.com/admin/sidekiq/queues
2. Find the queue you want to drop and click "Delete"

## Dropping specific workers in the queue

In GitLab, it's possible that there are multiple workers that share the same
Sidekiq queue. If you do not want to drop the entire queue and only specific
types of workers, you can do this via a command-line tool.

Suppose you see a lot of `RepositoryMirrorUpdateWorker` instances that you want to kill.
BE CAREFUL WITH THIS COMMAND! You can see how many jobs would be killed using the `--dry-run`
parameter:

```
sudo gitlab-rails runner /tmp/sq.rb kill <WORKER NAME> --dry-run
```

For example:

```
sudo gitlab-rails runner /tmp/sq.rb kill RepositoryMirrorUpdateWorker --dry-run
```

You can omit the `--dry-run` option if you want to kill the jobs.
Putting script in `/tmp` is one way of making sure its readable by `git` user
with default umask setting. Otherwise rails console will treat the path as
Ruby string and [most likely err](https://github.com/rails/rails/blob/v4.2.8/railties/lib/rails/commands/runner.rb#L58-L63).

## Dropping jobs for a specific user

Suppose user `foo` is generating a lot of import jobs. You can use the Sidekiq
API in the Rails console to remove those specific jobs. To do this, we must
first identify the arguments that are run with this Sidekiq job.

1. Find the worker in question in https://gitlab.com/gitlab-org/gitlab-ee/tree/master/app/workers.
For example, jobs in the `repository_import` queue correspond to `repository_import_worker.rb`: https://gitlab.com/gitlab-org/gitlab-ee/blob/master/app/workers/repository_import_worker.rb.

2. Look at the arguments specified in `def perform` method. In this example,
   `project_id` is the only argument.

Now that we know we are looking for jobs that have a `project_id`, we can find out which
projects are owned by the user. In the Rails console (`sudo gitlab-rails console`):

```ruby
user = User.find_by(username: 'foo')
id_list = user.projects.pluck(:id)
```

To kill any matching projects, we can run the following in the same console:

```ruby
queue = Sidekiq::Queue.new('repository_import')
queue.each { |job| job.delete if id_list.include?(job.args[0]) }
```

### Kill running jobs (as opposed to removing them from a queue) ###

to get a list of jobs that you want to kill:
```ruby
types_of_jobs_to_kill = ["elastic_indexer", "elastic_commit_indexer", "elastic_namespace_indexer"]
workers = Sidekiq::Workers.new  # get an object holding references to all running jobs, see sidekiq docs for more info
running_elastic_jobs = workers.to_enum(:each).select { |pid, tid, work| types_of_jobs_to_kill.include?(work["queue"]) }
```

At the moment of writing, we do not handle killing of running jobs.

You can do it by killing the sidekiq worker. Elastic jobs, can be stopped by recreating the ES index (using a rake task, see [ES integration docs](https://docs.gitlab.com/ee/integration/elasticsearch.html)).

## References

* https://gitlab.com/gitlab-com/infrastructure/issues/677
* https://gitlab.com/gitlab-com/infrastructure/issues/606
* https://gitlab.com/gitlab-com/infrastructure/issues/584
* https://docs.gitlab.com/ee/administration/troubleshooting/sidekiq.html

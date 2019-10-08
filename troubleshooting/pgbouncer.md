# Sidekiq is using most of its PgBouncer connections

## Symptoms

* Message in #alerts-gprd: _Sidekiq is using most of its PgBouncer connections_

## Troubleshoot

1. Check the [PostgreSQL dashboard](https://dashboards.gitlab.net/d/000000144/postgresql-overview?orgId=1) and look at several graphs:
    * `PGBouncer Errors`
    * `Slow Lock Acquires`
    * `Locks across all hosts`

2. Find the PostgreSQL master and take a dump of all SQL queries:

    ```sql
    COPY (SELECT * FROM pg_stat_activity) TO '/tmp/queries.csv' With CSV DELIMITER ',';
    ```

3. Download `sq.rb` and run it to log all Sidekiq jobs and their arguments:

    ```sh
    curl -o /tmp/sq.rb https://gitlab.com/gitlab-com/runbooks/blob/master/troubleshooting/db_scripts/sq.rb
    sudo gitlab-rails runner /tmp/sq.rb > /tmp/sidekiq-jobs.txt
    ```

4. Look inside the file for the Sidekiq queue breakdown. For example, you might see something like:

    ```
    -----------
    Queue size:
    -----------
    Gitlab::GithubImport::ImportPullRequestWorker: 17620
    PipelineProcessWorker: 11000
    GitGarbageCollectWorker: 9607
    PagesDomainVerificationWorker: 8428
    BuildFinishedWorker: 6702
    CreateGpgSignatureWorker: 4807
    BuildQueueWorker: 2792
    StageUpdateWorker: 531
    ProjectImportScheduleWorker: 243
    RepositoryUpdateMirrorWorker: 234
    BuildSuccessWorker: 45
    DetectRepositoryLanguagesWorker: 20
    BuildHooksWorker: 16
    ExpireJobCacheWorker: 14
    <snip>
    ```

    You will also see lines such as:

    ```
    ["Gitlab::GithubImport::ImportPullRequestWorker", [10267729, {"iid"=>13081, "...
    ```

    Each line represents a job that is encoded as JSON payload. The
    first item is the class name of the worker
    (e.g. `Gitlab::GithubImport::ImportPullRequestWorker`).

    The next item in the array is the job arguments. Inside the job
    arguments, the first item for this worker is the project ID. Using
    this information, you can selectively kill jobs by their project ID.

5. For example, suppose project ID 1000 appears to have many jobs, and
   you want to remove all jobs relating to that project.  In
   `gitlab-rails console`, you can run:

    ```ruby
    project_id = 1000

    queue = Sidekiq::Queue.all
      queue.each do |q|
        q.each do |job|
          next unless job.klass == 'Gitlab::GithubImport::ImportPullRequestWorker'

          job.delete if job.args[0] == project_id
        end
      end
    end
    ```

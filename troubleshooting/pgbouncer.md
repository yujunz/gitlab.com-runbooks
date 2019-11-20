# Sidekiq or Web/API is using most of its PgBouncer connections

## Symptoms

* Message in #alerts-general: _The pgbouncer service (main stage), pgbouncer_async_pool component has a saturation exceeding SLO_
* Message in #alerts: _PGBouncer is logging errors_

## Troubleshoot

1. Imbalance on pgbouncer connections
  * On the dedicated pgbouncer fleet (for rw connections to the master), `pgbouncer_async_pool` is for sidekiq, `pgbouncer_sync_pool` for web/api.
  * Check the [PGBouncer Overview dashboard](https://dashboards.gitlab.net/d/PwlB97Jmk/pgbouncer-overview?orgId=1) and look at `Backend Connections`:
      * if only one pgbouncer node is getting most connections, then either
        * one pgbouncer node was down during a deployment and all (long persisting) db connections where made to the other one
        * or the healthcheck service on one of the 2 active nodes is down.
      * Solution: 
        * check the iLB [status](https://console.cloud.google.com/net-services/loadbalancing/details/internal/us-east1/gprd-pgbouncer-regional?project=gitlab-production&angularJsUrl=%2Fnet-services%2Floadbalancing%2Fdetails%2Finternal%2Fus-east1%2Fgprd-pgbouncer-regional%3Fproject%3Dgitlab-production&authuser=1) and [metrics](https://app.google.stackdriver.com/metrics-explorer?project=gitlab-production&timeSelection=%7B%22timeRange%22:%226h%22%7D&xyChart=%7B%22dataSets%22:%5B%7B%22timeSeriesFilter%22:%7B%22filter%22:%22metric.type%3D%5C%22loadbalancing.googleapis.com%2Fl3%2Finternal%2Fegress_packets_count%5C%22%20resource.type%3D%5C%22internal_tcp_lb_rule%5C%22%20resource.label.%5C%22load_balancer_name%5C%22%3D%5C%22gprd-pgbouncer-regional%5C%22%22,%22perSeriesAligner%22:%22ALIGN_RATE%22,%22crossSeriesReducer%22:%22REDUCE_SUM%22,%22secondaryCrossSeriesReducer%22:%22REDUCE_NONE%22,%22minAlignmentPeriod%22:%2260s%22,%22groupByFields%22:%5B%22resource.label.%5C%22backend_name%5C%22%22%5D,%22unitOverride%22:%221%22%7D,%22targetAxis%22:%22Y1%22,%22plotType%22:%22LINE%22%7D%5D,%22options%22:%7B%22mode%22:%22COLOR%22%7D,%22constantLines%22:%5B%5D,%22timeshiftDuration%22:%220s%22,%22y1Axis%22:%7B%22label%22:%22y1Axis%22,%22scale%22:%22LINEAR%22%7D%7D&isAutoRefresh=true)
    * make sure the healthcheck is up on the 2 nodes that should be active:
      * `systemctl status pgbouncer-leader-check.service`
    * `HUP` all unicorns and sidekiq workers to re-establish db connections.
      * web: `knife ssh -C4 'role:gprd-base-fe-web AND chef_environment:gprd' 'hostname -f && sudo gitlab-ctl hup unicorn && sleep 10'`
      * api: `knife ssh -C1 'name:api-*-sv-gprd*' 'hostname -f && sudo gitlab-ctl hup unicorn && sleep 30'`
      * sidekiq: `knife ssh -C4 'name:sidekiq-*-sv-gprd*' 'hostname -f && sudo gitlab-ctl hup sidekiq && sleep 10'`
1. Too many Sidekiq connections
  * Check the [PostgreSQL dashboard](https://dashboards.gitlab.net/d/000000144/postgresql-overview?orgId=1) and look at several graphs:
    * `PGBouncer Errors`
    * `Slow Lock Acquires`
    * `Locks across all hosts`

  * Find the PostgreSQL master and take a dump of all SQL queries:

    ```sql
    COPY (SELECT * FROM pg_stat_activity) TO '/tmp/queries.csv' With CSV DELIMITER ',';
    ```

  * Download `sq.rb` and run it to log all Sidekiq jobs and their arguments:

    ```sh
    curl -o /tmp/sq.rb https://gitlab.com/gitlab-com/runbooks/blob/master/troubleshooting/db_scripts/sq.rb
    sudo gitlab-rails runner /tmp/sq.rb > /tmp/sidekiq-jobs.txt
    ```

  * Look inside the file for the Sidekiq queue breakdown. For example, you might see something like:

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

  *  For example, suppose project ID 1000 appears to have many jobs, and
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

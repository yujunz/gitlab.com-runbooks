## CI troubleshooting introduction

GitLab.com and dev.gitlab.org shared runners consists from a number of components and machines.

### Components

We can define these components:

1. GitLab Sidekiq - processes pipeline, and updates jobs statuses,
1. GitLab Unicorn - is used to request new job, download or upload artifacts,
1. Workhorse - is used to implement long polling and capacity limiting of `builds/register` and `job/request` endpoint,
1. Runner Manager - is used to asking GitLab for new jobs, provision new machines and run received jobs on provisioned machines,
1. Machine - an actual provisioned VM on which jobs are run. Usually, they consist out of Docker Engine to which Runner Manager connects and instruments jobs creation.

### Data flow

Let's shortly describe data flow and most crucial components of Shared Runners setup on GitLab.com and dev.gitlab.org.

1. Everything starts at GitLab application level.
1. User pushes changes to GitLab,
1. Changes are received and being processed by Git daemon,
1. Git daemon executes `gitlab-shell` post-receive hook of the repository,
1. Post receive hook enqueues `PostReceive` Sidekiq job on Redis,
1. Sidekiq job is now being executed,
1. During PostReceive execution a `CreatePipelineService` is being fired,
1. We read and analyze `.gitlab-ci.yml`, create `ci_pipeline` and `ci_builds` object,
1. We then execute `ProcessPipelineWorker` on `ci_pipeline` to enqueue jobs,
1. Any job that should be run by runner does change its state from `created` to `pending`,
1. Runner asks either `builds/register` (old CI API), `job/request` (new API v4) endpoint,
1. GitLab Unicorn executes SQL query that checks for list of "potential" jobs that should be executed by runner in question,
1. We validate that potential runner can run job, if this is true we transition the job from `pending` to `running` and attach `runner_id`,
1. Job serialized data is returned to Runner Manager,
1. Runner Manager when receives a job is starting an executor (docker, kubernetes or docker+machine),
1. Runner reads received payload and creates a set of containers: helper (to clone sources, to download/upload artifacts and caches), build (to run user-provided script), services (provided in `.gitlab-ci.yml`),
1. Once all containers do finish the result of the job is sent do GitLab,

### Creating machines

Runner Manager does manage Machines as described in this document: https://gitlab.com/gitlab-org/gitlab-ci-multi-runner/blob/master/docs/configuration/autoscale.md#autoscaling-algorithm-and-parameters.

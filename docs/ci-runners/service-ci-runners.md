<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Ci-runners Service

* **Responsible Teams**:
  * [infrastructure-caches-ci-queues](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=ci-runners&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22ci-runners%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:CI Runner"

## Logging

* [shared runners](https://log.gprd.gitlab.net/goto/b9aed2474a7ffe194a10d4445a02893a)

<!-- END_MARKER -->

## Purpose of the service

CI Runners are used by customers to run CI jobs for any project hosted on GitLab.com.

Because this allows even free accounts to execute arbitrary code for up to 2000 wallclock minutes per month,
it is ripe for abuse.

Quick reference links:
* [CI dashboard](https://dashboards.gitlab.net/d/000000159/ci)
* [CI architecture summary](https://about.gitlab.com/handbook/engineering/infrastructure/production-architecture/ci-architecture.html)
* [CI Runner docs](https://docs.gitlab.com/runner/)
* [CI Runner project source code, including curated links to the docs in README.md](https://gitlab.com/gitlab-org/gitlab-runner)
* [Related runbooks](https://gitlab.com/gitlab-com/runbooks/blob/master/troubleshooting/cicd/)

## Common Alert: The `ci-runners` service (`main` stage) has a apdex score (latency) below SLO

Because ci-runner resources are limited, when a burst of numerous or expensive new jobs are created,
this can delay the start of other jobs, possibly causing the above alert.

We aim for pending jobs to be started promptly, so a scheduling delay can cause PagerDuty to alert the
on-call engineer about SLO violation.

Quick reference:
* [Example PagerDuty alert](https://gitlab.pagerduty.com/incidents/PVDAS6I)
* [Apdex formula (search for `type: ci-runners`)](https://gitlab.com/gitlab-com/runbooks/blob/master/rules/service_apdex.yml)

The following are some known ways for this alert to be triggered.

### Abuse of resources: Cryptocurrency mining

The most common known pattern of abuse is cryptocurrency mining.

Because we limit wallclock minutes, not CPU minutes, miners are motivated to spawn numerous concurrent jobs, to make the most of their wallclock minutes.

Miners often create numerous accounts on GitLab.com, each having its own namespace, project, and CI pipeline.  Typically these projects have nearly identical `.gitlab-ci.yml` files, with only superficial differences.  Often these files will maximize parallelism, by defining many jobs that can run concurrently and possibly also specifying that each of those jobs should individually be run in parallel.

### Surge of Scheduled Pipelines

When creating a scheduled pipeline in the GitLab UI there are some handy defaults. Unfortunately, they result in a lot of users scheduling pipelines to trigger at the same time on the same day, week, or month.

The biggest spike is caused at 04:00 UTC. This spike is increased on Sundays (for jobs scheduled to be weekly) and on the first of the month (for jobs scheduled monthly). If the first of the month is also a Sunday this is additive and the spike will be even larger.

In the case of a scheduled pipeline surge triggering the alert, it should resolve within ~15 minutes. If it doesn't it likely indicates there's more than just the one cause of the alert (e.g. there is a scheduled pipeline surge **and** abusive behavior in the system)

### GitLab.com usage has outgrown it's surge capacity

Each runner manager tries to maintain a [pool of idle virtual machines](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/-/blob/master/roles/gitlab-runner-srm-gce.json#L19) 
to assign to new jobs. This allows jobs to start as soon as they're assigned without waiting for the VM spin-up time. However, if the idle pool is exhausted and new jobs keep coming in, the new jobs will have to wait for availble VMs.

This scenario actually describes the above two scenarios as well, however because the idle count is a hard coded value per runner manager, over time it will need to be updated as usage on GitLab.com grows.

#### How to identify active abusive accounts?

To find miners running numerous concurrent jobs from one or more accounts (a.k.a. namespaces), use the following dashboard panels to find any namespaces with numerous (say, 800-1000) jobs in either the `Pending` or `Running` state.  Adjust the dashboard's timespan to include at least a few hours prior to your alert about the SLO violation for jobs being promptly started.

* ["CI Runners Service" -> "CI" -> "Jobs queue" -> "Running jobs on shared-runners"](https://dashboards.gitlab.net/d/000000159/ci?orgId=1&panelId=60&fullscreen&from=now-3h&to=now)
* ["CI Runners Service" -> "CI" -> "Jobs queue" -> "Pending jobs with shared-runners enabled"](https://dashboards.gitlab.net/d/000000159/ci?orgId=1&panelId=33&fullscreen&from=now-3h&to=now)

These namespace ids are all that the abuse-team needs to block the accounts and cancel the running or pending jobs, so if the situation is dire, skip ahead to the "Mitigation" step.

Caveats:
* Normally the namespace called "namespace" can be ignored.  It is an "everything else" bucket for the many small namespaces that did not rank in the top-N that get individually tallied.  Usually you can ignore it, but if it has an outrageously high count of jobs, that might indicate there are numerous namespaces being collectively aggressive in scheduling jobs (which would warrant further research).
* Namespace 9970 is the `gitlab-org` namespace and is expected to routinely have heavy CI activity.

#### Investigation

To translate these namespace ids into namespace names and URLs, you can (a) run `/chatops run namespace <id>`, (b) query the Rails console, or (c) query the Postgres database directly.

##### Option A: ChatOps command

The easiest way is to use this ChatOps command in Slack to lookup the namespace name:

```
/chatops run namespace <namespace_id>
```

##### Option B: Database query

Connect to any Postgres database (primary or replica) and get a `psql` prompt:

```shell
$ ssh <username>-db@gprd-console
```

or

```shell
$ ssh patroni-01-db-gprd.c.gitlab-production.internal   # Any patroni is fine, replica or primary.
$ sudo gitlab-psql
```

Put your namespace ids into the IN-list of the following query:

```sql
select
  id,
  created_at,
  updated_at,
  'https://gitlab.com/' || path as namespace_url
from
  namespaces
where
  id in ( 6334677, 6336008, ... )
order by
  created_at
;
```

##### Option C: Rails console query

Connect to the Rails console server:

```shell
$ ssh <username>-rails@gprd-console
```

Put your namespace ids into the array at the start of this iterator expression:

```ruby
%w[6334677 6336008].each { |id| n = Namespace.find(id); puts "#{id} (#{n.name}): https://gitlab.com/#{n.path}" }
```

##### Review the namespaces via the GitLab web UI

To view the namespace (and its projects), you will probably need to authenticate to GitLab.com using your admin account (e.g. "msmiley+admin@gitlab.com") rather than your normal account, since abusive projects tend to be marked as private.

Often (but not always), both the namespace and the project are disposable, having minimal setup and content, apart from the `.gitlab-ci.yml` file that defines the pipeline jobs.  For reference, here is an [example namespace](https://gitlab.com/zabuzhkofaina), its one [project](https://gitlab.com/zabuzhkofaina/zabuzhkofaina), and its [`.gitlab-ci.yml` file](https://gitlab.com/zabuzhkofaina/zabuzhkofaina/blob/master/.gitlab-ci.yml).

In your browser, view the namespace and its project(s).  Determine if the namespace or project looks suspicious.  Does the namespace and project have minimal setup?  Were they freshly created very recently and lack activity apart from initial setup?  Is the project empty apart from the `.gitlab-ci.yml` file that defines the pipeline jobs?

View the `.gitlab-ci.yml` file.  Does its job definition look like a miner?  Does it download an executable, possibly a separate configuration file, and then run numerous long-running jobs?

#### Mitigation

Contact the Abuse Team via Slack (`@abuse-team`), and ask them to run `Scrubber` for the namespace ids you identified above as abusive.

Quick reference:
* [Scrubber runbook](https://gitlab.com/gitlab-com/gl-security/abuse-team/abuse/wikis/Runbook/Mitigation-Tool-%28Scrubber%29)

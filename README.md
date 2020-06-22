# Gitlab On-call Run Books

This project provides a guidance for Infrastructure Reliability Engineers and Managers who are starting an on-call shift or responding to an incident. If you haven't yet, review the [Incident Management](https://about.gitlab.com/handbook/engineering/infrastructure/incident-management/index.html) page in the handbook before reading on.

## On-Call

GitLab Reliability Engineers and Managers provide 24x7 on-call coverage to ensure incidents are responded to promptly and resolved as quickly as possible.

### Shifts

We use [PagerDuty](https://gitlab.pagerduty.com) to manage our on-call
schedule and incident alerting. We currently have two escalation policies for , one for [Production Incidents](https://gitlab.pagerduty.com/escalation_policies#P7IG7DS) and the other for [Production Database Assistance](https://gitlab.pagerduty.com/escalation_policies#P1SMG60). They are staffed by SREs and DBREs, respectively, and Reliability Engineering Managers.

Currently, rotations are weekly and the day's schedule is split 12/12 hours with engineers
on call as close to daytime hours as their geographical region allows. We hope to hire so that shifts are an 8/8/8 hours split, but we're not staffed sufficiently yet across timezones.

### Joining the On-Call Rotation

When a new engineer joins the team and is ready to start shadowing for an on-call rotation,
[overrides][pagerduty-overrides] should be enabled for the relevant on-call hours during that
rotation. Once they have completed shadowing and are comfortable/ready to be inserted into the
primary rotations, update the membership list for the appropriate schedule to [add the new team
member][pagerduty-add-user].

This [pagerduty forum post][pagerduty-shadow-schedule] was referenced when setting up the [blank
shadow schedule][pagerduty-blank-schedule] and initial [overrides][pagerduty-overrides] for
on-boarding new team member


## Checklists

- [Engineer on Call (EOC)](on-call/checklists/eoc.md)
- [Incident Manager on Call (IMOC)](on-call/checklists/imoc.md)

To start with the right foot let's define a set of tasks that are nice things to do before you go any further in your week

By performing these tasks we will keep the [broken window
effect](https://en.wikipedia.org/wiki/Broken_windows_theory) under control, preventing future pain
and mess.

## Things to keep an eye on

### Issues

First check [the on-call issues][on-call-issues] to familiarize yourself with what has been
happening lately. Also, keep an eye on the [#production][slack-production] and
[#incident-management][slack-incident-management] channels for discussion around any on-going
issues.

### Alerts

Start by checking how many alerts are in flight right now

-   go to the [fleet overview dashboard](https://dashboards.gitlab.net/dashboard/db/fleet-overview) and check the number of Active Alerts, it should be 0. If it is not 0
    -   go to the alerts dashboard and check what is being triggered
        -   [azure][prometheus-azure]
        -   [gprd prometheus][prometheus-gprd]
        -   [gprd prometheus-app][prometheus-app-gprd]
    -   watch the [#alerts][slack-alerts], [#alerts-general][slack-alerts-general], and [#alerts-gstg][slack-alerts-gstg] channels for alert notifications; each alert here should point you to the right [runbook][runbook-repo] to fix it.
    -   if they don't, you have more work to do.
    -   be sure to create an issue, particularly to declare toil so we can work on it and suppress it.

### Prometheus targets down

Check how many targets are not scraped at the moment. alerts are in flight right now, to do this:

-   go to the [fleet overview dashboard](https://dashboards.gitlab.net/dashboard/db/fleet-overview) and check the number of Targets down. It should be 0. If it is not 0
    -   go to the [targets down list] and check what is.
        -   [azure][prometheus-azure-targets-down]
        -   [gprd prometheus][prometheus-gprd-targets-down]
        -   [gprd prometheus-app][prometheus-app-gprd-targets-down]
    -   try to figure out why there is scraping problems and try to fix it. Note that sometimes there can be temporary scraping problems because of exporter errors.
    -   be sure to create an issue, particularly to declare toil so we can work on it and suppress it.

## Incidents

First: don't panic.

If you are feeling overwhelmed, escalate to the [IMOC](https://about.gitlab.com/handbook/engineering/infrastructure/incident-management/#incident-manager-on-call-imoc-responsibilities).
Whoever is in that role can help you get other people to help with whatever is needed.  Our goal is to resolve the incident in a timely manner, but sometimes that means slowing down and making sure we get the right people involved.  Accuracy is as important or more than speed.

Roles for an incident can be found in the [incident management section of the handbook](https://about.gitlab.com/handbook/engineering/infrastructure/incident-management/)

If you need to declare an incident, [follow these instructions located in the handbook](https://about.gitlab.com/handbook/engineering/infrastructure/incident-management/#reporting-an-incident).

## Communication Tools

If you do end up needing to post and update about an incident, we use [Status.io](https://status.io)

On status.io, you can [Make an incident](https://app.status.io/dashboard/5b36dc6502d06804c08349f7/incident/create) and Tweet, post to Slack, IRC, Webhooks, and email via checkboxes on creating or updating the incident.

The incident will also have an affected infrastructure section where you can pick components of the GitLab.com application and the underlying services/containers should we have an incident due to a provider.

You can update incidents with the Update Status button on an existing incident, again you can tweet, etc from that update point.

Remember to close out the incident when the issue is resolved.  Also, when possible, put the issue and/or google doc in the post mortem link.

# Production Incidents

## Roles

During an incident there are at least 2 roles, and one more optional

* Production engineers will
  * Open a war room on Zoom immediately to have high a bandwidth communication channel.
  * Create a [Google Doc](https://docs.google.com) to gather the timeline of events.
  * Publish this document using the _File_, _Publish to web..._ function.
  * Make this document GitLab editable by clicking on the `Share` icon and selecting _Advanced_, _Change_, then _On - GitLab_.
  * Tweet `GitLab.com is having a major outage, we're working on resolving it in a Google Doc LINK` with a link to this document to make the community aware.
  * Redact the names to remove the blame. Only use team-member-1, -2, -3, etc.
  * Document partial findings or guessing as we learn.
  * Write a post mortem issue when the incident is solved, and label it with `outage`

* The point person will
  * Handle updating the @gitlabstatus account explaining what is going on in a simple yet reassuring way.
  * Synchronize efforts across the production engineering team
  * Pull other people in when consultation is needed.
  * Declare a major outage when we are meeting the definition.
  * Post `@channel, we have a major outage and need help creating a live streaming war room, refer to [runbooks-production-incident]` into the #general slack channel.
  * Post `@channel, we have a major outage and need help reviewing public documents` into the #marketing slack channel.
  * Post `@channel, we have a major outage and are working to solve it, you can find the public doc <here>` into the #devrel slack channel.
  * Move the war room to a paid account so the meeting is not time limited.
  * Coordinate with the security team and the communications manager and use the [breach notification policy](https://about.gitlab.com/security/#data-breach-notification-policy) to determine if a breach of user data has occurred and notify any affected users.

* The communications manager will
  * Setup a not time limited Zoom war room and provide it to the point person to move all the production engineers there.
  * Setup Youtube Live Streaming int the war room following [this Zoom guide](https://support.zoom.us/hc/en-us/articles/115000350446-Streaming-a-Webinar-on-YouTube-Live) (for this you will need to have access to the GitLab Youtube account, ask someone from People Ops to grant you so)

* The Marketing representative will
  * Review the Google Doc to provide proper context when needed.
  * Include a note about how is this outage impacting customers in the document.
  * Decide how to handle further communications when the outage is already handled.

## General guidelines for production incidents.

* Is this an emergency incident?
	* Are we losing data?
	* Is GitLab.com not working or offline?
	* Has the incident affected users for greater than 1 hour?
* [Tweet](docs/uncategorized/tweeting-guidelines.md) in a reassuring but informative way to let the people know what's going on
* Join the `#production` channel
* Define a _point person_ or _incident owner_, this is the person that will gather all the data and coordinate the efforts.
* For emergency incidents define [Roles](https://gitlab.com/gitlab-com/runbooks/blob/master/howto/manage-production-incidents.md)
	* Point person
        * in the `#production` channel: "@here I'm taking point" and pin the message for the duration of the emergency.
	* Communications manager
	* Marketing representative.
	* Start a war room using zoom
	* Share the link in the #production channel
	* Stream the zoom call live.  [Streaming a Webinar on YouTube Live – Zoom Help Center](https://support.zoom.us/hc/en-us/articles/115000350446-Streaming-a-Webinar-on-YouTube-Live)
* For non-emergency incidents.
	* Establish who is the point person on the incident.
	    * in the `#production` channel: "@here I'm taking point" and pin the message for the duration of the incident.
	* Start a war room using zoom if it will save time
	* Share the link in the #production channel
* Organize:
  * If intervention is required (i.e. a non self-healing service)
  * Create a Google Doc to gather the timeline of events.
  * Publish this document using the File, Publish to web... function.
  * Make this document GitLab editable by clicking on the Share icon and selecting Advanced, Change, then On - GitLab.
* If the _point person_ needs someone to do something, give a direct command: _@someone: please run `this` command_
* Be sure to be in sync - if you are going to reboot a service, say so: _I'm bouncing server X_
* If you have conflicting information, **stop and think**, bounce ideas, escalate
* Gather information when the incident is done - logs, samples of graphs, whatever could help figuring out what happened
* Update the [Production Oncall Log](https://docs.google.com/document/d/1nWDqjzBwzYecn9Dcl4hy1s4MLng_uMq-8yGRMxtgK6M/edit#heading=h.nmt24c52ggf5)
* If we lack monitoring or alerting Open an issue and label as `monitoring`, even if you close issue immediately. See [handbook](https://about.gitlab.com/handbook/infrastructure/)
* Keep in mind [GitLab's data breach notification policy](https://about.gitlab.com/security/#data-breach-notification-policy) and work with the security team to determine if a user data breach has occurred and if notification needs to be provided.
* Once the incident is resolved, [Tweet](docs/uncategorized/tweeting-guidelines.md)  an update and let users know the issue is resolved.

# References

## Communication Guidelines
* [When the lead is away](docs/uncategorized/lead-away.md)
* [Tweeting Guidelines](docs/uncategorized/tweeting-guidelines.md)
* [Production Incident Communication Strategy](howto/manage-production-incidents.md)
* [Database Incidents](incidents/database.md)

## CRITICAL
* Spend one minute and create issue for outage, don't forget about `outage` label as specified in [handbook](https://about.gitlab.com/handbook/engineering/infrastructure/).

### PostgreSQL

* [PostgreSQL](docs/patroni/postgres.md)
* [more postgresql](docs/patroni/postgresql.md)
* [PgBouncer](docs/pgbouncer/pgbouncer-1.md)
* [PostgreSQL High Availability & Failovers](docs/patroni/pg-ha.md)
* [PostgreSQL switchover](howto/postgresql-switchover.md)
* [Read-only Load Balancing](docs/ci-runners/load-balancing.md)
* [Add a new secondary replica](docs/patroni/postgresql-replica.md)
* [Database backups](docs/patroni/postgresql-backups-wale-walg.md)
* [Database backups restore testing](docs/patroni/postgresql-backups-wale-walg.md#database-backups-restore-testing)
* [Rebuild a corrupt index](docs/patroni/postgresql.md#rebuild-a-corrupt-index)
* [Checking PostgreSQL health with postgres-checkup](docs/patroni/postgres-checkup.md)

### Frontend Services

* [GitLab Pages returns 404](docs/pages/gitlab-pages.md)
* [HAProxy is missing workers](docs/uncategorized/chef.md)
* [Worker's root filesystem is running out of space](docs/monitoring/filesystem_alerts.md)
* [Azure Load Balancers Misbehave](docs/frontend/load-balancer-outage.md)
* [GitLab registry is down](docs/registry/gitlab-registry.md)
* [Sidekiq stats no longer showing](docs/sidekiq/sidekiq_stats_no_longer_showing.md)
* [Gemnasium is down](docs/uncategorized/gemnasium_is_down.md)
* [Blocking a project causing high load](docs/uncategorized/block-high-load-project.md)

### Supporting Services

* [Redis replication has stopped](troubleshooting/redis_replication.md)
* [Redis replication setup](howto/redis-new-cluster-replication.md)
* [Sentry is down](docs/monitoring/sentry-is-down.md)

### Gitaly

* [Gitaly error rate is too high](docs/gitaly/gitaly-error-rate.md)
* [Gitaly latency is too high](docs/gitaly/gitaly-latency.md)
* [Sidekiq Queues are out of control](docs/sidekiq/large-sidekiq-queue.md)
* [Workers have huge load because of cat-files](docs/uncategorized/workers-high-load.md)
* [Test pushing through all the git nodes](docs/git/git.md)
* [How to gracefully restart gitaly-ruby](docs/gitaly/gracefully-restart-gitaly-ruby.md)
* [Debugging gitaly with gitaly-debug](docs/gitaly/gitaly-debugging-tool.md)
* [Gitaly token rotation](docs/gitaly/gitaly-token-rotation.md)
* [Praefect is down](docs/praefect/praefect-startup.md)
* [Praefect error rate is too high](docs/praefect/praefect-error-rate.md)

### CI

* [Large number of CI pending builds](troubleshooting/ci_pending_builds.md)
* [The CI runner manager report a high DO Token Rate Limit usage](troubleshooting/ci_runner_manager_do_limits.md)
* [The CI runner manager report a high number of errors](troubleshooting/ci_runner_manager_errors.md)
* [Runners cache is down](docs/ci-runners/runners_cache_is_down.md)
* [Runners registry is down](docs/ci-runners/runners_registry_is_down.md)
* [Runners cache free disk space is less than 20%](docs/ci-runners/runners_cache_disk_space.md)
* [Too many connections on Runner's cache server](troubleshooting/ci_too_many_connections_on_runners_cache_server.md)

### Geo

* [Geo database replication](docs/patroni/geo-patroni-cluster.md)

### ELK

* [`mapper_parsing_exception` errors](troubleshooting/elk_mapper_parsing_exception.md)

## Non-Critical

* [SSL certificate expires](docs/frontend/ssl_cert.md)
* [Troubleshoot git stuck processes](docs/git/git-stuck-processes.md)

## Non-Core Applications

* [version.gitlab.com](docs/version/version-gitlab-com.md)

### Chef/Knife

* [General Troubleshooting](docs/uncategorized/chef.md)
* [Error executing action `create` on resource 'directory[/some/path]'](docs/uncategorized/stale-file-handles.md)

### Certificates
* [Certificate runbooks](certificates/README.md)

## Learning

### Alerting and monitoring
* [GitLab monitoring overview](docs/monitoring/monitoring-overview.md)
* [How to add alerts: Alerts manual](docs/monitoring/alerts_manual.md)
* [How to add/update deadman switches](docs/uncategorized/deadman-switches.md)
* [How to silence alerts](howto/silence-alerts.md)
* [Alert for SSL certificate expiration](docs/uncategorized/alert-for-ssl-certificate-expiration.md)
* [Working with Grafana](monitoring/grafana.md)
* [Working with Prometheus](monitoring/prometheus.md)
* [Upgrade Prometheus and exporters](docs/monitoring/update-prometheus-and-exporters.md)
* [Use mtail to capture metrics from logs](docs/uncategorized/mtail.md)

### CI

* [Introduction to Shared Runners](troubleshooting/ci_introduction.md)
* [Understand CI graphs](troubleshooting/ci_graphs.md)

### Access Requests

* [Deal with various kinds of access requests](docs/uncategorized/access-requests.md)

### Deploy

* [Get the diff between dev versions](docs/uncategorized/dev-environment.md#figure-out-the-diff-of-deployed-versions)
* [Deploy GitLab.com](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/doc/deploying.md)
* [Rollback GitLab.com](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/doc/deploying.md#rolling-back-gitlabcom)
* [Deploy staging.GitLab.com](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/doc/staging.md)
* [Refresh data on staging.gitlab.com](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/doc/staging.md)
* [Background Migrations](https://gitlab.com/gitlab-org/release/docs/-/blob/master/runbooks/background-migrations.md)

### Work with the fleet and the rails app

* [Reload unicorn with zero downtime](docs/uncategorized/manage-workers.md#reload-unicorn-with-zero-downtime)
* [How to perform zero downtime frontend host reboot](docs/uncategorized/manage-workers.md#how-to-perform-zero-downtime-frontend-host-reboot)
* [Gracefully restart sidekiq jobs](docs/uncategorized/manage-workers.md#gracefully-restart-sidekiq-jobs)
* [Start a rails console in the staging environment](docs/uncategorized/staging-environment.md#run-a-rails-console-in-staging-environment)
* [Start a redis console in the staging environment](docs/uncategorized/staging-environment.md#run-a-redis-console-in-staging-environment)
* [Start a psql console in the staging environment](docs/uncategorized/staging-environment.md#run-a-psql-console-in-staging-environment)
* [Force a failover with postgres](docs/patroni/patroni-management.md#failoverswitchover)
* [Force a failover with redis](docs/uncategorized/manage-pacemaker.md#force-a-failover)
* [Use aptly](docs/uncategorized/aptly.md)
* [Disable PackageCloud](docs/uncategorized/stop-or-start-packagecloud.md)
* [Re-index a package in PackageCloud](docs/uncategorized/reindex-package-in-packagecloud.md)
* [Access hosts in GCP](docs/uncategorized/access-gcp-hosts.md)

### Restore Backups

* [Deleted Project Restoration](docs/uncategorized/deleted-project-restore.md)
* [PostgreSQL Backups: WAL-E, WAL-G](docs/patroni/postgresql-backups-wale-walg.md)
* [Work with Azure Snapshots](docs/uncategorized/azure-snapshots.md)
* [Work with GCP Snapshots](docs/uncategorized/gcp-snapshots.md)
* [PackageCloud Infrastructure And Recovery](docs/uncategorized/packagecloud-infrastructure.md)

### Work with storage

* [Understanding GitLab Storage Shards](docs/gitaly/storage-sharding.md)
* [How to re-balance GitLab Storage Shards](docs/gitaly/storage-rebalancing.md)
* [Build and Deploy New Storage Servers](docs/gitaly/storage-servers.md)
* [Manage uploads](docs/uncategorized/uploads.md)

### Mangle front end load balancers
* [Isolate a worker by disabling the service in the LBs](docs/frontend/block-things-in-haproxy.md#disable-a-whole-service-in-a-load-balancer)
* [Deny a path in the load balancers](docs/frontend/block-things-in-haproxy.md#deny-a-path-with-the-delete-http-method)
* [Purchasing/Renewing SSL Certificates](docs/frontend/ssl_cert-1.md)

### Work with Chef
* [Create users, rotate or remove keys from chef](docs/uncategorized/manage-chef.md)
* [Update packages manually for a given role](docs/uncategorized/manage-workers.md#update-packages-fleet-wide)
* [Rename a node already in Chef](docs/uncategorized/rename-nodes.md)
* [Reprovisioning nodes](docs/uncategorized/reprovisioning-nodes.md)
* [Speed up chefspec tests](docs/uncategorized/chefspec.md#tests-are-taking-too-long-to-run)
* [Manage Chef Cookbooks](docs/uncategorized/chef-documentation.md)
* [Chef Guidelines](docs/uncategorized/chef-guidelines.md)
* [Chef Vault](docs/uncategorized/chef-vault.md)
* [Debug failed provisioning](howto/debug-failed-chef-provisioning.md)

### Work with CI Infrastructure
* [Update GitLab Runner on runners managers](docs/runner/update-gitlab-runner-on-managers.md)
* [Investigate Abuse Reports](docs/ci-runners/ci-investigate-abuse.md)
* [Create runners manager for GitLab.com](docs/ci-runners/create-runners-manager-node.md)
* [Update docker-machine](docs/uncategorized/upgrade-docker-machine.md)
* [CI project namespace check](docs/ci-runners/ci-project-namespace-check.md)

### Work with Infrastructure Providers (VMs)
* [Getting Support w/ RackSpace for GCP/GKE](howto/GCP-rackspace-support.md)
* [Create a DO VM for a Service Engineer](docs/uncategorized/create-do-vm-for-service-engineer.md)
* [Create VMs in Azure, add disks, etc](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/doc/azure.md#managing-vms-in-azure)
* [Bootstrap a new VM](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/doc/new-vps.md)
* [Remove existing node checklist](docs/uncategorized/remove-node.md)

### Manually ban an IP or netblock
* [Ban a single IP using Redis and Rack Attack](docs/redis/ban-an-IP-with-redis.md)
* [Ban a netblock on HAProxy](docs/frontend/ban-netblocks-on-haproxy.md)

### Dealing with Spam
* [General procedures for fighting spam in snippets, issues, projects, and comments](https://docs.google.com/document/d/1V0X2aYiNTZE1npzeqDvq-dhNFZsEPsL__FqKOMXOjE8)

### Manage Marvin, our infra bot
* [Manage cog](docs/uncategorized/manage-cog.md)

### ElasticStack (previously Elasticsearch)

Selected elastic documents and resources:

- elastic/
    - doc/
        - [elastic-cloud.md](elastic/doc/elastic-cloud.md) (hosted ES provider docs)
        - [exercises](elastic/doc/exercises) (e.g. cluster performance tuning)
        - [kibana.md](elastic/doc/kibana.md)
        - [README.md](elastic/doc/README.md) (ES overview)
        - troubleshooting/
            - [README.md](elastic/doc/troubleshooting/README.md) (troubleshooting overview)
    - [scripts/](elastic/scripts) (api calls used for admin tasks documented as bash scripts)
    - watchers/

### ElasticStack integration in Gitlab (indexing Gitlab data)

[elasticsearch-integration-in-gitlab.md](elastic-integration/doc/elasticsearch-integration-in-gitlab.md)

### Logging

Selected logging documents and resources:

- logging/
    - doc/
        - [exercises](logging/doc/exercises) (e.g. searching logs in Kibana)
        - [README.md](logging/doc/README.md) (logging overview)
            - [quick-start](logging/doc/README.md#quick-start)
            - [what-are-we-logging](logging/doc/README.md#what-are-we-logging)
            - [searching-logs](logging/doc/README.md#searching-logs)
            - [logging-infrastructure-overview](logging/doc/README.md#logging-infrastructure-overview)
        - troubleshooting/
            - [README.md](logging/doc/troubleshooting/README.md)

### Internal DNS
* [Managing internal DNS](docs/uncategorized/internal_dns.md)

### Debug and monitor
* [Tracing the source of an expensive query](docs/ci-runners/tracing-app-db-queries.md)
* [Work with Kibana (logs view)](logging/doc/README.md#searching-logs)

### Secrets
* [Working with Google Cloud secrets](docs/uncategorized/working-with-gcloud-secrets.md)

### Security

* [Working with the CloudFlare WAF/CDN](howto/externalvendors/cloudflare.md)
* [Uptycs osquery](docs/uncategorized/uptycs_osquery.md)
* [Uptycs osquery troubleshooting](docs/uncategorized/uptycs_osqueryd.md)

### Other
* [Setup oauth2-proxy protection for web based application](docs/uncategorized/setup-oauth2-proxy-protected-application.md)
* [Register new domain(s)](docs/uncategorized/domain-registration.md)
* [Manage DNS entries](docs/uncategorized/manage-dns-entries.md)
* [Setup and Use my Yubikey](docs/uncategorized/yubikey.md)
* [Purge Git data](docs/git/purge-git-data.md)
* [Getting Started with Kubernetes and GitLab.com](docs/uncategorized/k8s-gitlab.md)
* [Using Chatops bot to run commands across the fleet](docs/uncategorized/deploycmd.md)

### Gitter
* [MongoDB operations](docs/git/gitter/mongodb-operations.md)
* [Renew the Gitter TLS certificate](docs/git/gitter/renew-certificates.md)

### Manage Package Signing Keys
* [Manage Package Signing Keys](docs/uncategorized/manage-package-signing-keys.md)

### Other Servers and Services
* [GitHost / GitLab Hosted](docs/git/githost.md)

### Adding runbooks rules
* Make it quick - add links for checks
* Don't make me think - write clear guidelines, write expectations
* Recommended structure
  * Symptoms - how can I quickly tell that this is what is going on
  * Pre-checks - how can I be 100% sure
  * Resolution - what do I have to do to fix it
  * Post-checks - how can I be 100% sure that it is solved
  * Rollback - optional, how can I undo my fix

# Developing in this repo

## Generating a new runbooks image

To generate a new image you must follow the git commit guidelines below, this
will trigger a semantic version bump which will then cause a new pipeline
that will build and tag the new image

### Git Commit Guidelines

This project uses [Semantic Versioning](https://semver.org). We use commit
messages to automatically determine the version bumps, so they should adhere to
the conventions of [Conventional Commits (v1.0.0-beta.2)](https://www.conventionalcommits.org/en/v1.0.0-beta.2/).

#### TL;DR

- Commit messages starting with `fix: ` trigger a patch version bump
- Commit messages starting with `feat: ` trigger a minor version bump
- Commit messages starting with `BREAKING CHANGE: ` trigger a major version bump.
- If you don't want to publish a new image, do not use the above starting
  strings.

### Automatic versioning

Each push to `master` triggers a [`semantic-release`](https://semantic-release.gitbook.io/semantic-release/)
CI job that determines and pushes a new version tag (if any) based on the
last version tagged and the new commits pushed. Notice that this means that if a
Merge Request contains, for example, several `feat: ` commits, only one minor
version bump will occur on merge. If your Merge Request includes several commits
you may prefer to ignore the prefix on each individual commit and instead add
an empty commit summarizing your changes like so:

```
git commit --allow-empty -m '[BREAKING CHANGE|feat|fix]: <changelog summary message>'
```

## Tool Versioning

This project has adopted [`adsf version-manager`](https://github.com/asdf-vm/asdf) for tool versioning.

Installation instructions for `asdf` can be found at https://asdf-vm.com/#/core-manage-asdf-vm?id=install.

For compatibility, please configure the following line in `~/.asdfrc`

```
legacy_version_file = yes
```

### Required tooling

Our `asdf` toolset uses the following plugins:

* `golang`: `asdf plugin add golang`
* `ruby`: `asdf plugin add ruby`
* `go-jsonnet`: `asdf plugin add go-jsonnet https://gitlab.com/craigfurman/asdf-go-jsonnet`.

Once you have installed these plugins, run the following command to install the required versions.

```console
$ asdf install
go-jsonnet 0.16.0 is already installed
golang 1.14 is already installed
ruby 2.6.5 is already installed
$ # Confirm everything is working with....
$ asdf current
go-jsonnet     0.16.0   (set by ~/runbooks/.tool-versions)
golang         1.14     (set by ~/runbooks/.tool-versions)
ruby           2.6.5    (set by ~/runbooks/.ruby-version)
```

### Go, Jsonnet

We use `.tool-versions` to record the version of go-jsonnet that should be used
for local development. The `asdf` version manager is used by some team members
to automatically switch versions based on the contents of this file. It should
be kept up to date. `images/runtools_build/Dockerfile` contains the version of
go-jsonnet we use in CI. This should be kept in sync with `.tool-versions`, and
a (non-gating) CI job enforces this.

To install [go-jsonnet](https://github.com/google/go-jsonnet), you have a few
options.

You could follow that project's README to install manually;

Or via homebrew:

```
brew install go-jsonnet
```
Or use [an asdf plugin](https://gitlab.com/craigfurman/asdf-go-jsonnet).

### Ruby

Additional to `adsf`, many developers use `rbenv`, `rvm` or other tooling, so, for convenience, we maintain
the standard `.ruby-version` file for the Ruby version. ASDF needs to be configured using
the `legacy_version_file = yes` setting described in the [parent section](#tool-versioning).

## Contributing

Please see the [contribution guidelines](CONTRIBUTING.md)

# But always remember!

![Dont Panic](img/dont_panic_towel.jpg)


<!-- Links -->
[on-call-issues]:                   https://gitlab.com/gitlab-com/infrastructure/issues?scope=all&utf8=%E2%9C%93&state=all&label_name[]=oncall

[pagerduty-add-user]:               https://support.pagerduty.com/docs/editing-schedules#section-adding-users
[pagerduty-amer]:                   https://gitlab.pagerduty.com/schedules#PKN8L5Q
[pagerduty-amer-shadow]:            https://gitlab.pagerduty.com/schedules#P0HRY7O
[pagerduty-blank-schedule]:         https://community.pagerduty.com/t/creating-a-blank-schedule/212
[pagerduty-emea]:                   https://gitlab.pagerduty.com/schedules#PWDTHYI
[pagerduty-emea-shadow]:            https://gitlab.pagerduty.com/schedules#PSWRHSH
[pagerduty-overrides]:              https://support.pagerduty.com/docs/editing-schedules#section-create-and-delete-overrides
[pagerduty-shadow-schedule]:        https://community.pagerduty.com/t/creating-a-shadow-schedule-to-onboard-new-employees/214

[prometheus-azure]:                 https://prometheus.gitlab.com/alerts
[prometheus-azure-targets-down]:    https://prometheus.gitlab.com/consoles/up.html
[prometheus-gprd]:                  https://prometheus.gprd.gitlab.net/alerts
[prometheus-gprd-targets-down]:     https://prometheus.gprd.gitlab.net/consoles/up.html
[prometheus-app-gprd]:              https://prometheus-app.gprd.gitlab.net/alerts
[prometheus-app-gprd-targets-down]: https://prometheus-app.gprd.gitlab.net/consoles/up.html

[runbook-repo]:                     https://gitlab.com/gitlab-com/runbooks

[slack-alerts]:                     https://gitlab.slack.com/channels/alerts
[slack-alerts-general]:             https://gitlab.slack.com/channels/alerts-general
[slack-alerts-gstg]:                https://gitlab.slack.com/channels/alerts-gstg
[slack-incident-management]:        https://gitlab.slack.com/channels/incident-management
[slack-production]:                 https://gitlab.slack.com/channels/production

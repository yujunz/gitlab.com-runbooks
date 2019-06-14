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

- [EMOC](on-call/eoc.md)
- [IMOC](on-call/imoc.md)

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

If you are feeling overwhelmed, escalate to the [IMOC or CMOC](https://about.gitlab.com/handbook/engineering/infrastructure/incident-management/#roles).  
Whoever is in that role can help you get other people to help with whatever is needed.  Our goal is to resolve the incident in a timely manner, but sometimes that means slowing down and making sure we get the right people involved.  Accuracy is as important or more than speed.

Roles for an incident can be found in the [incident management section of the handbook](https://about.gitlab.com/handbook/engineering/infrastructure/incident-management/)

If you need to start an incident, you can post in the #incident channel(https://gitlab.slack.com/messages/CB7P5CJS1)
If you use /start-incident - a bot will make and issue/google doc and zoom link for you.

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
  * Synchronize efforts accross the production engineering team
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
* [Tweet](howto/tweeting-guidelines.md) in a reassuring but informative way to let the people know what's going on
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
* Once the incident is resolved, [Tweet](howto/tweeting-guidelines.md)  an update and let users know the issue is resolved.

# References

## Communication Guidelines
* [When the lead is away](howto/lead-away.md)
* [Tweeting Guidelines](howto/tweeting-guidelines.md)
* [Production Incident Communication Strategy](howto/manage-production-incidents.md)
* [Database Incidents](incidents/database.md)

## CRITICAL
* Spend one minute and create issue for outage, don't forget about `outage` label as specified in [handbook](https://about.gitlab.com/handbook/engineering/infrastructure/).

### PostgreSQL

* [Postgresql](troubleshooting/postgres.md)
* [more postgresql](howto/postgresql.md)
* [PgBouncer](howto/pgbouncer.md)
* [PostgreSQL High Availability & Failovers](howto/pg-ha.md)
* [PostgreSQL switchover](howto/postgresql-switchover.md)
* [Read-only Load Balancing](howto/load-balancing.md)
* [Add a new secondary replica](howto/postgresql-replica.md)
* [Database backups](howto/using-wale-gpg.md)
* [Database backups restore testing](https://gitlab.com/gitlab-restore/postgres-01.db.prd.gitlab.com/)

### Frontend Services

* [GitLab Pages returns 404](troubleshooting/gitlab-pages.md)
* [HAProxy is missing workers](troubleshooting/chef.md)
* [Worker's root filesystem is running out of space](troubleshooting/filesystem_alerts.md)
* [Azure Load Balancers Misbehave](troubleshooting/load-balancer-outage.md)
* [GitLab registry is down](troubleshooting/gitlab-registry.md)
* [Sidekiq stats no longer showing](troubleshooting/sidekiq_stats_no_longer_showing.md)
* [Gemnasium is down](troubleshooting/gemnasium_is_down.md)
* [Blocking a project causing high load](howto/block-high-load-project.md)

### Supporting Services

* [Redis replication has stopped](troubleshooting/redis_replication.md)
* [Sentry is down](troubleshooting/sentry-is-down.md)

### Gitaly

* [Gitaly error rate is too high](troubleshooting/gitaly-error-rate.md)
* [Gitaly latency is too high](troubleshooting/gitaly-latency.md)
* [Sidekiq Queues are out of control](troubleshooting/large-sidekiq-queue.md)
* [Workers have huge load because of cat-files](troubleshooting/workers-high-load.md)
* [Test pushing through all the git nodes](troubleshooting/git.md)
* [How to gracefully restart gitaly-ruby](howto/gracefully-restart-gitaly-ruby.md)
* [Debugging gitaly with gitaly-debug](howto/gitaly-debugging-tool.md)

### CI

* [Large number of CI pending builds](troubleshooting/ci_pending_builds.md)
* [The CI runner manager report a high DO Token Rate Limit usage](troubleshooting/ci_runner_manager_do_limits.md)
* [The CI runner manager report a high number of errors](troubleshooting/ci_runner_manager_errors.md)
* [Runners cache is down](troubleshooting/runners_cache_is_down.md)
* [Runners registry is down](troubleshooting/runners_registry_is_down.md)
* [Runners cache free disk space is less than 20%](troubleshooting/runners_cache_disk_space.md)
* [Too many connections on Runner's cache server](troubleshooting/ci_too_many_connections_on_runners_cache_server.md)

### ELK

* [`mapper_parsing_exception` errors](troubleshooting/elk_mapper_parsing_exception.md)

## Non-Critical

* [SSL certificate expires](troubleshooting/ssl_cert.md)
* [Troubleshoot git stuck processes](troubleshooting/git-stuck-processes.md)

### Chef/Knife

* [General Troubleshooting](troubleshooting/chef.md)
* [Error executing action `create` on resource 'directory[/some/path]'](troubleshooting/stale-file-handles.md)

## Learning

### Alerting and monitoring
* [GitLab monitoring overview](howto/monitoring-overview.md)
* [How to add alerts: Alerts manual](howto/alerts_manual.md)
* [How to add/update deadman switches](howto/deadman-switches.md)
* [How to silence alerts](howto/silence-alerts.md)
* [Alert for SSL certificate expiration](howto/alert-for-ssl-certificate-expiration.md)
* [Working with Grafana](monitoring/grafana.md)
* [Working with Prometheus](monitoring/prometheus.md)
* [Upgrade Prometheus and exporters](howto/update-prometheus-and-exporters.md)
* [Use mtail to capture metrics from logs](howto/mtail.md)

### CI

* [Introduction to Shared Runners](troubleshooting/ci_introduction.md)
* [Understand CI graphs](troubleshooting/ci_graphs.md)

### Access Requests

* [Deal with various kinds of access requests](howto/access-requests.md)

### Deploy

* [Get the diff between dev versions](howto/dev-environment.md#figure-out-the-diff-of-deployed-versions)
* [Deploy GitLab.com](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/doc/deploying.md)
* [Rollback GitLab.com](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/doc/deploying.md#rolling-back-gitlabcom)
* [Deploy staging.GitLab.com](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/doc/staging.md)
* [Refresh data on staging.gitlab.com](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/doc/staging.md)

### Work with the fleet and the rails app

* [Reload unicorn with zero downtime](howto/manage-workers.md#reload-unicorn-with-zero-downtime)
* [How to perform zero downtime frontend host reboot](howto/manage-workers.md#how-to-perform-zero-downtime-frontend-host-reboot)
* [Gracefully restart sidekiq jobs](howto/manage-workers.md#gracefully-restart-sidekiq-jobs)
* [Start a rails console in the staging environment](howto/staging-environment.md#run-a-rails-console-in-staging-environment)
* [Start a redis console in the staging environment](howto/staging-environment.md#run-a-redis-console-in-staging-environment)
* [Start a psql console in the staging environment](howto/staging-environment.md#run-a-psql-console-in-staging-environment)
* [Force a failover with postgres or redis](howto/manage-pacemaker.md#force-a-failover)
* [Use aptly](howto/aptly.md)
* [Disable PackageCloud](howto/stop-or-start-packagecloud.md)
* [Re-index a package in PackageCloud](howto/reindex-package-in-packagecloud.md)
* [Access hosts in GCP](howto/access-gcp-hosts.md)

### Restore Backups

* [Community Project Restoration](howto/community-project-restore.md)
* [Database Backups and Replication with Encrypted WAL-E](howto/using-wale-gpg.md)
* [Work with Azure Snapshots](howto/azure-snapshots.md)
* [Work with GCP Snapshots](howto/gcp-snapshots.md)
* [PackageCloud Infrastructure And Recovery](howto/packagecloud-infrastructure.md)

### Work with storage

* [Understanding GitLab Storage Shards](howto/sharding.md)
* [Build and Deploy New Storage Servers](howto/storage-servers.md)

### Mangle front end load balancers
* [Isolate a worker by disabling the service in the LBs](howto/block-things-in-haproxy.md#disable-a-whole-service-in-a-load-balancer)
* [Deny a path in the load balancers](howto/block-things-in-haproxy.md#deny-a-path-with-the-delete-http-method)
* [Purchasing/Renewing SSL Certificates](howto/ssl_cert.md)

### Work with Chef
* [Create users, rotate or remove keys from chef](howto/manage-chef.md)
* [Update packages manually for a given role](howto/manage-workers.md#update-packages-fleet-wide)
* [Rename a node already in Chef](howto/rename-nodes.md)
* [Reprovisioning nodes](howto/reprovisioning-nodes.md)
* [Speed up chefspec tests](howto/chefspec.md#tests-are-taking-too-long-to-run)
* [Manage Chef Cookbooks](howto/chef-documentation.md)
* [Chef Guidelines](howto/chef-guidelines.md)
* [Chef Vault](howto/chef-vault.md)

### Work with CI Infrastructure
* [Update GitLab Runner on runners managers](howto/update-gitlab-runner-on-managers.md)
* [Investigate Abuse Reports](howto/ci-investigate-abuse.md)
* [Create runners manager for GitLab.com](howto/create-runners-manager-node.md)
* [Update docker-machine](howto/upgrade-docker-machine.md)
* [CI project namespace check](howto/ci-project-namespace-check.md)

### Work with Infrastructure Providers (VMs)
* [Getting Support w/ RackSpace for GCP/GKE](howto/GCP-rackspace-support.md)
* [Create a DO VM for a Service Engineer](howto/create-do-vm-for-service-engineer.md)
* [Create VMs in Azure, add disks, etc](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/doc/azure.md#managing-vms-in-azure)
* [Bootstrap a new VM](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/doc/new-vps.md)
* [Remove existing node checklist](howto/remove-node.md)

### Manually ban an IP or netblock
* [Ban a single IP using Redis and Rack Attack](howto/ban-an-IP-with-redis.md)
* [Ban a netblock on HAProxy](howto/ban-netblocks-on-haproxy.md)

### Dealing with Spam
* [General procedures for fighting spam in snippets, issues, projects, and comments](https://docs.google.com/document/d/1V0X2aYiNTZE1npzeqDvq-dhNFZsEPsL__FqKOMXOjE8)

### Manage Marvin, our infra bot
* [Manage cog](howto/manage-cog.md)

### Elasticsearch
* [How to work with ES](howto/elasticsearch.md)
* [Elastic Cloud](howto/elastic-cloud.md)
* [ES integration in gitlab](howto/elasticsearch-integration-in-gitlab.md)
* [`mapper_parsing_exception` errors](troubleshooting/elk_mapper_parsing_exception.md)
* [elastic-watcher](https://gitlab.com/gitlab-com/runbooks/tree/master/elastic-watcher)

### Internal DNS
* [Managing internal DNS](howto/internal_dns.md)

### Debug and monitor
* [Tracing the source of an expensive query](howto/tracing-app-db-queries.md)
* [Work with Kibana (logs view)](howto/kibana.md)

### Secrets
* [Working with Google Cloud secrets](howto/working-with-gcloud-secrets.md)

### Security
* [Uptycs osquery](howto/uptycs_osquery.md)
* [Uptycs osquery troubleshooting](troubleshooting/uptycs_osqueryd.md)

### Other
* [Setup oauth2-proxy protection for web based application](howto/setup-oauth2-proxy-protected-application.md)
* [Register new domain(s)](howto/domain-registration.md)
* [Setup and Use my Yubikey](howto/yubikey.md)
* [Purge Git data](howto/purge-git-data.md)

### Gitter
* [MongoDB operations](howto/gitter/mongodb-operations.md)
* [Renew the Gitter TLS certificate](howto/gitter/renew-certificates.md)

### Manage Package Signing Keys
* [Manage Package Signing Keys](howto/manage-package-signing-keys.md)

### Other Servers and Services
* [GitHost / GitLab Hosted](howto/githost.md)

### Adding runbooks rules
* Make it quick - add links for checks
* Don't make me think - write clear guidelines, write expectations
* Recommended structure
  * Symptoms - how can I quickly tell that this is what is going on
  * Pre-checks - how can I be 100% sure
  * Resolution - what do I have to do to fix it
  * Post-checks - how can I be 100% sure that it is solved
  * Rollback - optional, how can I undo my fix

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
[prometheus-app-gprd]:              https://prometheus-app.gprdgitlab.net/alerts
[prometheus-app-gprd-targets-down]: https://prometheus-app.gprd.gitlab.net/consoles/up.html

[runbook-repo]:                     https://gitlab.com/gitlab-com/runbooks

[slack-alerts]:                     https://gitlab.slack.com/channels/alerts
[slack-alerts-general]:             https://gitlab.slack.com/channels/alerts-general
[slack-alerts-gstg]:                https://gitlab.slack.com/channels/alerts-gstg
[slack-incident-management]:        https://gitlab.slack.com/channels/incident-management
[slack-production]:                 https://gitlab.slack.com/channels/production


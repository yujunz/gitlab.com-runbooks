# Gitlab On Call Run Books

The aim of this project is to have a quick guide of what to do when an emergency arrives

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
* [How to silence alerts](howto/silence-alerts.md)
* [Alert for SSL certificate expiration](howto/alert-for-ssl-certificate-expiration.md)
* [Working with Grafana](monitoring/grafana.md)
* [Working with Prometheus](monitoring/prometheus.md)
* [Upgrade Prometheus and exporters](howto/update-prometheus-and-exporters.md)
* [Use mtail to capture metrics from logs](howto/mtail.md)

### CI
* [Introduction to Shared Runners](troubleshooting/ci_introduction.md)
* [Understand CI graphs](troubleshooting/ci_graphs.md)

### On Call
* [Common tasks to perform while on-call](howto/oncall.md)

### Access Requests
* [Deal with various kinds of access requests](howto/access-requests.md)

### Deploy
* [Get the diff between dev versions](howto/dev-environment.md#figure-out-the-diff-of-deployed-versions)
* [Deploy GitLab.com](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/doc/deploying.md)
* [Rollback GitLab.com](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/doc/deploying.md#rolling-back-gitlabcom)
* [Deploy staging.GitLab.com](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/doc/staging.md)
* [Refresh data on staging.gitlab.com](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/doc/staging.md)

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

### Restore Backups
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
* [Create VMs in Azure, add disks, etc](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/doc/azure.md#managing-vms-in-azure)
* [Bootstrap a new VM](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/doc/new-vps.md)
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

### Internal DNS
* [Managing internal DNS](howto/internal_dns.md)

### Debug and monitor
* [Tracing the source of an expensive query](howto/tracing-app-db-queries.md)
* [Work with Kibana (logs view)](howto/kibana.md)

### Secrets
* [Working with Google Cloud secrets](howto/working-with-gcloud-secrets.md)

### Other
* [Setup oauth2-proxy protection for web based application](howto/setup-oauth2-proxy-protected-application.md)
* [Register new domain(s)](howto/domain-registration.md)
* [Setup and Use my Yubikey](howto/yubikey.md)

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

# Gitlab On Call Run Books

The aim of this project is to have a quick guide of what to do when an emergency arrives

## CRITICAL

* Spend one minute and create issue for outage, don't forget about `outage` label as specified in [handbook](https://about.gitlab.com/handbook/infrastructure/).

## What to do when

* [Sidekiq Queues are out of control](troubleshooting/large-sidekiq-queue.md)
* [Workers have huge load because of cat-files](troubleshooting/workers-high-load.md)
* [GitLab Pages returns 404](troubleshooting/gitlab-pages.md)
* [HAProxy is missing workers](troubleshooting/chef.md)
* [Worker's root filesystem is running out of space](troubleshooting/filesystem_alerts.md)
* [Azure Load Balancers Misbehave](troubleshooting/load-balancer-outage.md)
* [Kibana is down](troubleshooting/kibana_is_down.md)
* [SSL certificate expires](troubleshooting/ssl_cert.md)
* [GitLab registry is down](troubleshooting/gitlab-registry.md)
* [Sidekiq stats no longer showing](troubleshooting/sidekiq_stats_no_longer_showing.md)
* [Sentry is down](troubleshooting/sentry-is-down.md)
* [Gitaly error rate is too high](troubleshooting/gitaly-error-rate.md)

### Replication fails

* [The DB replication has stopped](troubleshooting/postgresql_replication.md)
* [Redis replication has stopped](troubleshooting/redis_replication.md)
* [CRM has failed](troubleshooting/crm-failed.md)

### Chef/Knife

* [Nodes are missing chef roles](troubleshooting/chef.md)
* [Knife ssh does not work](troubleshooting/chef.md)

### CI

* [Introduction to Shared Runners](troubleshooting/ci_introduction.md)
* [Understand CI graphs](troubleshooting/ci_graphs.md)
* [Large number of CI pending builds](troubleshooting/ci_pending_builds.md)
* [The CI runner manager report a high DO Token Rate Limit usage](troubleshooting/ci_runner_manager_do_limits.md)
* [The CI runner manager report a high number of errors](troubleshooting/ci_runner_manager_errors.md)
* [Runners cache is down](troubleshooting/runners_cache_is_down.md)
* [Runners registry is down](troubleshooting/runners_registry_is_down.md)
* [Runners cache free disk space is less than 20%](troubleshooting/runners_cache_disk_space.md)

### CephFS

* [CephFS warns "failing to respond to cache pressure"](troubleshooting/cephfs.md)

## Alerting and monitoring

* [GitLab monitoring overview](howto/monitoring-overview.md)
* [How to add alerts: Alerts manual](howto/alerts_manual.md)
* [How to silence alerts](howto/silence-alerts.md)
* [Alert for SSL certificate expiration](howto/alert-for-ssl-certificate-expiration.md)
* [Working with Grafana](monitoring/grafana.md)
* [Working with Prometheus](monitoring/prometheus.md)
* [Upgrade Prometheus and exporters](howto/update-prometheus-and-exporters.md)

### Outdated

* [The NFS server `backend4` is gone](troubleshooting/nfs-server.md)
* [The DB server `db[45]` is under heavy load](troubleshooting/postgresql_heavy_load.md)
* [Redis keys state UNKNOWN](troubleshooting/redis_running_out_of_keys.md)
* [Locks in PostgreSQL or Stuck Sidekiq workers](troubleshooting/postgresql_locks.md)
* [Postfix queue is stale/growing](troubleshooting/postfix_queue.md)
* [Errors are reported in LOG files](troubleshooting/logwatch_alerts.md)

## How do I

### Deploy

* [Get the diff between dev versions](howto/dev-environment.md#figure-out-the-diff-of-deployed-versions)
* [Deploy GitLab.com](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/doc/deploying.md)
* [Rollback GitLab.com](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/doc/deploying.md#rolling-back-gitlabcom)
* [Deploy staging.GitLab.com](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/doc/staging.md)
* [Refresh data on staging.gitlab.com](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/doc/staging.md)

### Work with the fleet and the rails app

* [Restart unicorn with a zero downtime](howto/manage-workers.md#restart-unicorn-with-a-zero-downtime)
* [Gracefully restart sidekiq jobs](howto/manage-workers.md#gracefully-restart-sidekiq-jobs)
* [Start a rails console in the staging environment](howto/staging-environment.md#run-a-rails-console-in-staging-environment)
* [Start a redis console in the staging environment](howto/staging-environment.md#run-a-redis-console-in-staging-environment)
* [Start a psql console in the staging environment](howto/staging-environment.md#run-a-psql-console-in-staging-environment)
* [Force a failover with postgres or redis](howto/manage-pacemaker.md#force-a-failover)
* [Use aptly](howto/aptly.md)
* [Disable PackageCloud](howto/stop-or-start-packagecloud.md)

### Work with the Database

* [Database Backups and Replication with Wal-E](howto/using-wale.md)

### Work with storage

* [Migrate a project to CephFS or any other shard](howto/migrate-to-cephfs.md)
* [Administer and Maintain CephFS](howto/cephfs.md)

### Mangle front end load balancers

* [Isolate a worker by disabling the service in the LBs](howto/block-things-in-haproxy.md#disable-a-whole-service-in-a-load-balancer)
* [Deny a path in the load balancers](howto/block-things-in-haproxy.md#deny-a-path-with-the-delete-http-method)

### Work with Chef

* [Create users, rotate or remove keys from chef](howto/manage-chef.md)
* [Update packages manually for a given role](howto/manage-workers.md#update-packages-fleet-wide)
* [Rename a node already in Chef](howto/rename-nodes.md)
* [Speed up chefspec tests](howto/chefspec.md#tests-are-taking-too-long-to-run)
* [Retrieve old values in a Chef vault](howto/retrieve-old-chef-vault-values.md)
* [Manage Chef Cookbooks](howto/chef-documentation.md)
* [Best practices and tips](howto/chef-best-practices.md)

### Work with CI Infrastructure

* [Update GitLab Runner on runners managers](howto/update-gitlab-runner-on-managers.md)
* [Investigate Abuse Reports](howto/ci-investigate-abuse.md)
* [Create runners manager for GitLab.com](howto/create-runners-manager-node.md)
* [Update docker-machine](howto/upgrade-docker-machine.md)

### Work with Infrastructure Providers (VMs)

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

### Debug and monitor

* [Tracing the source of an expensive query](howto/tracing-app-db-queries.md)
* [Work with Kibana (logs view)](howto/kibana.md)
* [Work with Check_MK (Notifications, scheduled downtime, acknowledge problems)](howto/manage-checkmk.md)
* [Reload CheckMK metrics](howto/manage-checkmk.md#reload_host_metrics)
* [Run pgbadger to analyze queries](howto/postgresql.md#run-pgbadger-in-the-primary-database-server)

## General guidelines in an emergency

* Confirm that it is actually an emergency, challenge this: are we losing data? Is GitLab.com not working?
* [Tweet](howto/tweeting-guidelines.md) in a reassuring but informative way to let the people know what's going on
* Join the `#infrastructure` channel
* Define a _point person_ or _incident owner_, this is the person that will gather all the data and coordinate the efforts.
* Organize:
  * Establish who is the point person on the incident in the `#infrastructure` channel: "@here I'm taking point" and pin the message for the duration of the emergency.
  * Start a war room using zoom if it will save time
  * Share the link in the #infrastructure channel
  * If the _point person_ needs someone to do something, give a direct command: _@someone: please run `this` command_
* Be sure to be in sync - if you are going to reboot a service, say so: _I'm bouncing server X_
* If you have conflicting information, **stop and think**, bounce ideas, escalate
* Gather information when the incident is done - logs, samples of graphs, whatever could help figuring out what happened
* If we lack monitoring or alerting Open an issue and label as `monitoring`, even if you close issue immediately. See [handbook](https://about.gitlab.com/handbook/infrastructure/)

## Guidelines

* [Tweeting Guidelines](howto/tweeting-guidelines.md)
* [Production Incident Communication Strategy](howto/manage-production-incidents.md)

## Other Servers and Services

* [GitHost / GitLab Hosted](howto/githost.md)

## Adding runbooks rules

* Make it quick - add links for checks
* Don't make me think - write clear guidelines, write expectations
* Recommended structure
  * Symptoms - how can I quickly tell that this is what is going on
  * Pre-checks - how can I be 100% sure
  * Resolution - what do I have to do to fix it
  * Post-checks - how can I be 100% sure that it is solved
  * Rollback - optional, how can I undo my fix


# But always remember!

![Dont Panic](img/dont_panic_towel.jpg)

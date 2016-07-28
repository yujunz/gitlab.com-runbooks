# Gitlab On Call Run Books

The aim of this project is to have a quick guide of what to do when an emergency arrives


## IMPORTANT

* Spend one minute and create issue for outage, don't forget about `outage` label as specified in [handbook](https://about.gitlab.com/handbook/infrastructure/).


## What to do when

* [The NFS server `backend4` is gone](troubleshooting/nfs-server.md)
* [The DB server `db[45]` is under heavy load](troubleshooting/postgresql_heavy_load.md)
* [The DB replication has stopped](troubleshooting/postgresql_replication.md)
* [Redis replication has stopped](troubleshooting/redis_replication.md)
* [Redis keys state UNKNOWN](troubleshooting/redis_running_out_of_keys.md)
* [Locks in PostgreSQL or Stuck Sidekiq workers](troubleshooting/postgresql_locks.md)

## How do I

* [Deploy GitLab.com](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/doc/deploying.md)
* [Rollback GitLab.com](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/doc/deploying.md#rolling-back-gitlabcom)
* [Deploy staging.GitLab.com](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/doc/staging.md)
* [Refresh data on staging.gitlab.com](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/doc/staging.md)
* [Start a rails console in the staging environment](howto/staging-environment.md#run-a-rails-console-in-staging-environment)
* [Start a redis console in the staging environment](howto/staging-environment.md#run-a-redis-console-in-staging-environment)
* [Deny a path in the load balancers](howto/block-things-in-haproxy.md#deny-a-path-with-the-delete-http-method)
* [Isolate a worker by disabling the service in the LBs](howto/block-things-in-haproxy.md#disable-a-whole-service-in-a-load-balancer)
* [Restart unicorn with a zero downtime](howto/manage-workers.md#restart-unicorn-with-a-zero-downtime)
* [Gracefully restart sidekiq jobs](howto/manage-workers.md#gracefully-restart-sidekiq-jobs)
* [Reload CheckMK metrics](howto/manage-checkmk.md#reload_host_metrics)
* [Create users, rotate or remove keys from chef](howto/manage-chef.md)
* [Create VMs in Azure, add disks, etc](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/doc/azure.md#managing-vms-in-azure)
* [Bootstrap a new VM](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/doc/new-vps.md)
* [Update packages manually for a given role](howto/manage-workers.md#update-packages-fleet-wide)
* [Get the diff between dev versions](howto/dev-environment.md#figure-out-the-diff-of-deployed-versions)
* [Work with Kibana (logs view)](howto/kibana.md)
* [Force a failover with postgres or redis](howto/manage-pacemaker.md#force-a-failover)
* [Work with Check_MK (Notifications, scheduled downtime, acknowledge problems)](howto/checkmk.md)
* [Rename a node already in Chef](howto/rename-nodes.md)
* [Create a DO VM for a Service Engineer](howto/create-do-vm-for-service-engineer.md)

## General guidelines in an emergency

* Confirm that it is actually an emergency, challenge this: are we loosing data? Is GitLab.com not working?
* [Tweet](howto/tweeting-guidelines.md) in a reassuring but informative way to let the people know what's going on
* Join the `#alerts` channel
* Organize
  * open a hangout if it will save time: https://plus.google.com/hangouts/_/gitlab.com?authuser=1
  * share the link in the alerts channel
* If you need someone to do something, give a direct command: _@someone: please run `this` command_
* Be sure to be in sync - if you are going to reboot a service, say so: _I'm bouncing server X_
* If you have conflicting information, **stop and think**, bounce ideas, escalate
* Fix first, ask questions later.
* Gather information when the outage is done - logs, samples of graphs, whatever could help figuring out what happened
* Open an issue and put `monitoring` label on it, even if you close issue immediately. See [handbook](https://about.gitlab.com/handbook/infrastructure/)

## Guidelines

* [Tweeting Guidelines](howto/tweeting-guidelines.md)

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

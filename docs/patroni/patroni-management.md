# Patroni

## Scaling the cluster up

1. Increase the node count of `patroni` in [terraform][environment-variables].
1. Apply the terraform and wait for chef to converge.
1. On the new box, `gitlab-patronictl list` and ensure that the other cluster
   members are identical to those seen by running the same command on another
   cluster member.
1. `systemctl enable patroni && systemctl start patroni` (for some reason we do
   not automate this yet, but this operation is rare).
1. Follow the patroni logs. A pg_basebackup will take several hours, after which
   point streaming replication will begin. Silence alerts as necessary.

## Scaling the cluster down

1. Using this method, we can only delete the highest index of patroni. Make sure
   it isn't the primary!
1. Take the replica out of the read replica pool, and ensure it doesn't become
   the primary if we are unlucky enough to suffer a failover while scaling the
   cluster down: follow the [replica maintenance](#replica-maintenance)
   instructions.
1. Decrease the node count of `patroni` in [terraform][environment-variables].
   Carefully read the plan and apply the terraform.

### Checking status

`patroni` service is managed with systemd, so you can check the service status with `systemctl status patroni` and logs with `journalctl -u patroni` (it should be enabled and running).

Run `gitlab-patronictl list` to check the state of the patroni cluster, you should see the new node join the cluster and go through the following states:
- creating replica
- starting
- running

the node will also be added to the consul DNS entry, you can verify that with:
```
$ dig @127.0.0.1 -p8600 +short replica.patroni.service.consul.
```

At the moment of writing the database is 4TB big and it takes ~3h for a new node to catch up.

## Cluster information

Run `gitlab-patronictl list` on any Patroni member to list all the cluster members and their statuses.

```
patroni-01-db-gstg $ gitlab-patronictl list

+-----------------+------------------------------------------------+---------------+--------+---------+-----------+
|     Cluster     |                     Member                     |      Host     |  Role  |  State  | Lag in MB |
+-----------------+------------------------------------------------+---------------+--------+---------+-----------+
| pg11-ha-cluster | patroni-01-db-gstg.c.gitlab-staging-1.internal | 10.224.29.101 | Leader | running |         0 |
| pg11-ha-cluster | patroni-02-db-gstg.c.gitlab-staging-1.internal | 10.224.29.102 |        | running |         0 |
| pg11-ha-cluster | patroni-03-db-gstg.c.gitlab-staging-1.internal | 10.224.29.103 |        | running |         0 |
| pg11-ha-cluster | patroni-04-db-gstg.c.gitlab-staging-1.internal | 10.224.29.104 |        | running |         0 |
| pg11-ha-cluster | patroni-05-db-gstg.c.gitlab-staging-1.internal | 10.224.29.105 |        | running |         0 |
| pg11-ha-cluster | patroni-06-db-gstg.c.gitlab-staging-1.internal | 10.224.29.106 |        | running |         0 |
+-----------------+------------------------------------------------+---------------+--------+---------+-----------+
```

## Bootstrapping modes

### Normal bootstrapping

Normal bootstrapping is when you start a brand-new cluster with zero data. Patroni will create the PostgreSQL database
cluster using `initdb` with the options specified in `node['gitlab-patroni']['patroni']['config']['bootstrap']['initdb']`.

### Standby bootstrapping

Standby bootstrapping is starting a Patroni cluster that replicates from a remote master (i.e. not part of the Patroni cluster).

You need to specify the following Chef attributes to start a cluster in standby mode:

```ruby
node['gitlab-patroni']['patroni']['config']['bootstrap']['dcs']['standby_cluster'] = {
  "host": "remote.host.com",
  "port": "5432",
  "primary_slot_name": "patroni_repl_slot"
}
```

You'd need an extra setup on the remote master side:

1. Create a replication user with a username/password matching the ones you have in `node['gitlab-patroni']['patroni']['users']['replication']`
    * `CREATE USER "gitlab-replicator" LOGIN REPLICATION PASSWORD 'hunter1';`
1. Create a superuser with a username/password matching the ones you have in `node['gitlab-patroni']['patroni']['users']['superuser']`
    * `CREATE USER "gitlab-superuser" LOGIN SUPERUSER REPLICATION PASSWORD 'hunter1';`
1. Create a physical replication slot with the name you specified in `primary_slot_name` above
    * `SELECT * FROM pg_create_physical_replication_slot("patroni_repl_slot");`
1. Allow the replication user into the remote master through pg_hba entries
    * `host replication gitlab-replicator 10.0.0.0/8 md5`
    * `host replication gitlab-replicator 127.0.0.1/32 md5`

## Configuring PostgreSQL

You can specify any PostgreSQL parameter under `node['gitlab-patroni']['postgresql']['parameters']`, except for the following
parameters:

* `cluster_name`
* `wal_level`
* `hot_standby`
* `max_connections`
* `max_wal_senders`
* `wal_keep_segments`
* `max_prepared_transactions`
* `max_locks_per_transaction`
* `track_commit_timestamp`
* `max_replication_slots`
* `max_worker_processes`
* `wal_log_hints`

These parameters are specifically handled by Patroni for replication purposes. Some of them can't be changed (like `wal_log_hints`),
those that can be changed need to be specified under `node['gitlab-patroni']['patroni']['config']['bootstrap']['dcs']['postgresql']['parameters']`.

While nothing prevents you from specifying them under `node['gitlab-patroni']['postgresql']['parameters']`, it will likely confuse Patroni into
thinking that the cluster needs a restart (you may see a "Pending Restart" column when running `gitlab-patronictl list`).

When parameters are updated in Chef and propagated across the cluster, Patroni updates `postgresql.conf` then signals PostgreSQL to reload the configuration.
A restart may still be needed for some parameters, which you can see hints of in the logs, so you may need to run `gitlab-patronictl restart pg11-ha-cluster MEMBER_NAME`.

## Pausing Patroni

Quoting [Patroni docs][pause-docs]:

> Under certain circumstances Patroni needs to temporary step down from managing the cluster,
> while still retaining the cluster state in DCS.
> Possible use cases are uncommon activities on the cluster, such as major version upgrades or corruption recovery.
> During those activities nodes are often started and stopped for the reason unknown to Patroni,
> some nodes can be even temporary promoted, violating the assumption of running only one master.
> Therefore, Patroni needs to be able to "detach" from the running cluster, implementing an equivalent of the maintenance mode in Pacemaker.

Pausing the cluster disables automatic failover. This is desirable when doing tasks such as upgrading Consul,
or during a maintenance of the whole Patroni cluster.

It is important to disable `chef-client` before pausing the cluster,
otherwise a regular `chef-client` can revert the pause status.

To pause the cluster, run the following commands:

```
workstation        $ knife ssh roles:<env>-base-db-patroni 'sudo chef-client-disable "Database maintenance issue prod#xyz"'
patroni-01-db-gstg $ sudo gitlab-patronictl pause --wait pg11-ha-cluster
```

You can verify the result of pausing the cluster by running:

```
patroni-01-db-gstg $ sudo gitlab-patronictl list | grep 'Maintenance mode'
```

Run these commands to unpause/resume the cluster:

```
patroni-01-db-gstg $ sudo gitlab-patronictl resume --wait pg11-ha-cluster
workstation        $ knife ssh roles:<env>-base-db-patroni 'sudo chef-client-enable'
```

### Restarting Patroni When Paused

When the cluster is paused, before restarting the Patroni process, it is better
to check if Postgres postmaster didn't start when the system clock was skewed
for any reason:

```
patroni-01-db-gstg # postmaster=/var/opt/gitlab/postgresql/data/postmaster.pid;\
  postpid=$(cat $postmaster | head -1);\
  posttime=$(cat $postmaster | tail -n +3 | head -1);\
  btime=$(cat /proc/stat | grep btime | cut -d' ' -f2);\
  starttime=$(cat /proc/$postpid/stat | awk '{print $22}');\
  clktck=$(getconf CLK_TCK);\
  echo $((($starttime / $clktck + $btime) - $posttime))
```

If the command above returned a value higher than 3, then Patroni is going to
have [trouble starting][patroni-is-postmaster], so it is advised to fix this
issue with the help of a DBRE before restarting.

## Upgrading Patroni

Patroni version is controlled by Chef, upgrading it should be as simple as changing
an attribute in a role or a cookbook. Since Patroni would need to be restarted
(and subsequently, PostgreSQL), careful execution of the change is needed to
avoid database errors on the client side. While pausing Patroni (see relevant
section above) may be employed to restart Patroni without disturbing PostgreSQL,
it's not recommended to go this route as converging Chef can undo the pausing action,
which can introduce unintended results.

Instead, we recommend, one at a time, putting replicas into maintenance
(see relevant section below), upgrading Patroni through Chef, then putting replicas
out of maintenance. For the primary, we initiate a switchover to one of the upgraded
replicas then we upgraded it once it's been demoted.

The exact sequence of upgrading replicas has been encapsulated into an [Ansible playbook][upgrade-patroni-ansible].
The playbook expects an MR in the [chef-repo][chef-repo] project to be specified
in `variables.yml` under the target environment, and an API token to be used to
merge such MR.

The playbook can be run as follows:

```
$ git clone git@gitlab.com:gitlab-com/gl-infra/ansible-migrations.git
$ cd ansible-migrations
# Change relevant MRs in variables.yml
$ tmux
$ OPS_API_TOKEN=secure-token MIGRATION_ENV=gprd-or-gstg ansible-playbook -i production-1172/inventory.txt -M ./modules/ -e @production-1172/variables.yml production-1172/playbook.yml
```

## Replica Maintenance

If clients are connecting to replicas by means of [service
discovery][service-discovery] (as opposed to hard-coded list of hosts), you can
remove a replica from the list of hosts used by the clients by tagging it as not
suitable for failing over (`nofailover: true`) and load balancing (`noloadbalance: true`).

1. `sudo chef-client-disable "Database maintenance issue prod#xyz"`
1. Add a `tags` section to `/var/opt/gitlab/patroni/patroni.yml` on the
   node:

   ```
   tags:
     nofailover: true
     noloadbalance: true
   ```

1. `sudo systemctl reload patroni`
1. Test the efficacy of that reload by checking for the node name
   in the list of replicas:

   ```
   dig @127.0.0.1 -p 8600 db-replica.service.consul. SRV
   ```

    If the name is absent, then the reload worked.
1. Wait until all client connections are drained from the replica
   (it depends on the interval value set for the clients), use this
   command to track number of client connections:

   ```
   while true; do sudo pgb-console -c 'SHOW CLIENTS;' | grep gitlabhq_production | cut -d '|' -f 2 | awk '{$1=$1};1' | grep -v gitlab-monitor | wc -l; sleep 5; done
   ```

   Note: Usually there are three pgbouncer instances running
   on a single replica, so make sure they are all drained. Replace `pgb-console` above
   with `pgb-console-1` and `pgb-console-2`.

You can see an example of taking a node out of service [in this
issue](https://gitlab.com/gitlab-com/gl-infra/production/issues/1061).

### Permanently marking a replica as in maintenance

The method described above is suitable for short-term maintenance (e.g. 1 hour or less),
during which it's acceptable to keep `chef-client` disabled. However, if the replica is
expected to be in maintenance for many hours or days, it is undesirable to keep `chef-client` disabled
during such period.

Using node attributes to set such attributes is not ideal as node attributes are not as visible as roles,
and Chef nodes are removed when its GCP node is restarted, so it's not totally persistent.

Alternatively, we can utilize a special Chef role (`<env>-base-db-patroni-maintenance`)
that sets `nofailover` and `noloadbalance` to `true`, and then instruct Terraform to assign it to a particular instance.

1. In Terraform `patroni` module, add the following snippet:

   ```
   per_node_chef_run_list = {
     "3" = "\"role[${var.environment}-base-db-patroni-maintenance]\""
   }
   ```

   Replace `3` with the zero-based index of the replica we are targeting. In this example we're targeting
   `patroni-04`.
1. Apply the Terraform change.
1. In the target replica, run:
   ```
   sudo google_metadata_script_runner --script-type startup --debug
   ```
1. Verify the replica is in maintenance by checking for the node name
   in the list of replicas:

   ```
   dig @127.0.0.1 -p 8600 db-replica.service.consul. SRV
   ```

    If the name is absent, then the reload worked.

### Legacy Method (Consul Maintenance)

:warning: _This method only works if the clients are configured with
a `replica.patroni.service.consul.` DNS record, it won't work properly if they
are configured with `db-replica.service.consul.` record. Check
`/var/opt/gitlab/gitlab-rails/etc/database.yml` before you proceed._

In the past we have sometimes used consul directly to remove the replica from
the replica DNS entry (bear in mind this does not prevent the node from becoming
the primary).

```
patroni-01-db-gstg $ consul maint -enable -service=patroni-replica -reason="Production issue #xyz"
```

You can verify the action by running:

```
patroni-01-db-gstg $ dig @127.0.0.1 -p8600 +short replica.patroni.service.consul. | grep $(hostname -I) | wc -l # Prints 0
```

Wait until all client connections are drained from the replica (it depends on the interval value set for the clients),
use this command to track number of client connections:

```
patroni-01-db-gstg $ while true; do sudo pgb-console -c 'SHOW CLIENTS;' | grep gitlabhq_production | cut -d '|' -f 2 | awk '{$1=$1};1' | grep -v gitlab-monitor | wc -l; sleep 5; done
```

After you're done with the maintenance, disable Consul service maintenance and verify it:

```
patroni-01-db-gstg $ consul maint -disable -service=patroni-replica
patroni-01-db-gstg $ dig @127.0.0.1 -p8600 +short replica.patroni.service.consul. | grep $(hostname -I) | wc -l # Prints 1
```

## Failover/Switchover

Failover and Switchover are similar in their end-result, still there are slight differences between them:

* You can't do a switchover when the cluster has no leader
* Switchover can be scheduled to happen in a later time
* You need to specify a member to failover to, switchover does not and it will choose one at random.

That said, you can initiate any of them using `gitlab-patronictl switchover` or `gitlab-patronictl failover`
and entering values when prompted.

### Problems with replication after failover

Sometimes, after a failover, the old primary's timeline will have continued and
diverged from the new primary's timeline. Patroni will automatically attempt to
`pg_rewind` the timeline of the old primary to a point at which it can begin
replicating from the new primary, becoming healthy again. We have occasionally
seen this fail, for example with a statement timeout.

If for whatever reason you can't get the node to a healthy state and don't mind
waiting several hours, you can reinitialise the node:

```
root@pg$ gitlab-patronictl reinit pg11-ha-cluster patroni-XX-db-gprd.c.gitlab-production.internal
```

This command can be run from any member of the patroni cluster. It wipes the
data directory, takes a pg_basebackup from the new primary, and begins
replicating again.

### Diverged timeline WAL segments in GCS after failover

Our primary Postgres node is configured to archive WAL segments to GCS. These
segments are pulled by wal-g on another node in recovery mode, and replayed.
This process acts as a continuous test of our ability to restore our database
state from archived WAL segments. Sometimes, during a failover, both the old
primary and the new will have uploaded WAL segments, causing the DR archive that
is consuming these segments from GCS to not be able to replay the diverged
timeline. In the past we have solved this by rolling back the DR archive to an
earlier state.
See [../postgres-dr-delayed/postgres-dr-replicas.md](../postgres-dr-delayed/postgres-dr-replicas.md#restoring-with-a-disk-snapshot)

## Replacing a cluster with a new one

**Take care when doing these steps, results can be catastrophic**

In case there's a need to replace a current cluster with a new one, say, for testing purposes or
replication from a remote cluster got messed-up, you can remove the current cluster without the need
to destroy and re-create the node.

```
chef-repo $ knife ssh roles:gstg-base-db-patroni 'sudo systemctl stop patroni'
chef-repo $ knife ssh roles:gstg-base-db-patroni 'sudo rm -rf /var/opt/gitlab/postgresql/data' # TAKE CARE!
chef-repo $ knife ssh roles:gstg-base-db-patroni 'consul kv delete -recurse service/pg11-ha-cluster'
chef-repo $ knife ssh roles:gstg-base-db-patroni 'sudo systemctl start patroni'
```

You may need to adjust the Patroni Chef role before restarting the `patroni` service, like adding the standby config followed
by running `sudo chef-client` across the cluster.

[environment-variables]: https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/blob/989d22c9d15b75812d3d116a94513d34428c021e/environments/gstg/variables.tf#L382
[pause-docs]: https://github.com/zalando/patroni/blob/v1.5.0/docs/pause.rst
[service-discovery]: https://docs.gitlab.com/ee/administration/database_load_balancing.html#service-discovery
[patroni-is-postmaster]: https://github.com/zalando/patroni/blob/13c88e8b7a27b68e5c554d83d14e5cf640871ccc/patroni/postmaster.py#L55-L58
[upgrade-patroni-ansible]: https://gitlab.com/gitlab-com/gl-infra/ansible-migrations/blob/master/production-1172
[chef-repo]: https://ops.gitlab.net/gitlab-cookbooks/chef-repo/

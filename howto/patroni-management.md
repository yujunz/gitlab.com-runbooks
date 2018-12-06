# Patroni

## Scaling the cluster up or down

Increasing or decreasing the node count of `patroni` in an environment [variables][environment-variables],
followed by a Terraform provisioning, should be enough to add or remove nodes to the
Patroni cluster. A successful Chef run will start the `patroni` service will take
care of doing the base backup replication and the streaming replication afterwards.

## Cluster information

Run `gitlab-patronictl list` on any Patroni member to list all the cluster members and their statuses.

```
patroni-01-db-gstg $ gitlab-patronictl list

+---------------+------------------------------------------------+---------------+--------+---------+-----------+
|    Cluster    |                     Member                     |      Host     |  Role  |  State  | Lag in MB |
+---------------+------------------------------------------------+---------------+--------+---------+-----------+
| pg-ha-cluster | patroni-01-db-gstg.c.gitlab-staging-1.internal | 10.224.29.101 | Leader | running |         0 |
| pg-ha-cluster | patroni-02-db-gstg.c.gitlab-staging-1.internal | 10.224.29.102 |        | running |         0 |
| pg-ha-cluster | patroni-03-db-gstg.c.gitlab-staging-1.internal | 10.224.29.103 |        | running |         0 |
| pg-ha-cluster | patroni-04-db-gstg.c.gitlab-staging-1.internal | 10.224.29.104 |        | running |         0 |
| pg-ha-cluster | patroni-05-db-gstg.c.gitlab-staging-1.internal | 10.224.29.105 |        | running |         0 |
| pg-ha-cluster | patroni-06-db-gstg.c.gitlab-staging-1.internal | 10.224.29.106 |        | running |         0 |
+---------------+------------------------------------------------+---------------+--------+---------+-----------+
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
A restart may still be needed for some parameters, which you can see hints of in the logs, so you may need to run `gitlab-patronictl restart pg-ha-cluster MEMBER_NAME`.

## Pausing Patroni

Quoting [Patroni docs][pause-docs]:

> Under certain circumstances Patroni needs to temporary step down from managing the cluster,
> while still retaining the cluster state in DCS.
> Possible use cases are uncommon activities on the cluster, such as major version upgrades or corruption recovery.
> During those activities nodes are often started and stopped for the reason unknown to Patroni,
> some nodes can be even temporary promoted, violating the assumption of running only one master.
> Therefore, Patroni needs to be able to "detach" from the running cluster, implementing an equivalent of the maintenance mode in Pacemaker.

Pausing the cluster disables automatic failover. Run this command to pause the cluster:

```
patroni-01-db-gstg $ gitlab-patronictl pause --wait pg-ha-cluster
```

And this command to unpause/resume the cluster:

```
patroni-01-db-gstg $ gitlab-patronictl resume --wait pg-ha-cluster
```

## Failover/Switchover

Failover and Switchover are similar in their end-result, still there are slight differences between them:

* You can't do a switchover when the cluster has no leader
* Switchover can be scheduled to happen in a later time
* You need to specify a member to failover to, switchover does not and it will choose one at random.

That said, you can initiate any of them using `gitlab-patronictl switchover` or `gitlab-patronictl failover`
and entering values when prompted.

## Replacing a cluster with a new one

**Take care when doing these steps, results can be catastrophic**

In case there's a need to replace a current cluster with a new one, say, for testing purposes or
replication from a remote cluster got messed-up, you can remove the current cluster without the need
to destroy and re-create the node.

```
chef-repo $ knife ssh roles:gstg-base-db-patroni 'sudo systemctl stop patroni'
chef-repo $ knife ssh roles:gstg-base-db-patroni 'sudo rm -rf /var/opt/gitlab/postgresql/data' # TAKE CARE!
chef-repo $ knife ssh roles:gstg-base-db-patroni 'consul kv delete -recurse service/pg-ha-cluster'
chef-repo $ knife ssh roles:gstg-base-db-patroni 'sudo systemctl start patroni'
```

You may need to adjust the Patroni Chef role before restarting the `patroni` service, like adding the standby config followed
by running `sudo chef-client` across the cluster.

[environment-variables]: https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/blob/989d22c9d15b75812d3d116a94513d34428c021e/environments/gstg/variables.tf#L382
[pause-docs]: https://github.com/zalando/patroni/blob/v1.5.0/docs/pause.rst

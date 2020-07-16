# Geo Patroni Cluster Management

## Setup replication for a single node

These directions are for setting up archive recovery in geo environments
containing a "main" VM running most GitLab services, including postgres. The
database here is a singleton and not managed by patroni. Postgres here is
installed by the omnibus gitlab-ee package.

Setting up replication is necessary if a node is installed from scratch or if we
lost replication for too long and the necessary WAL files are not on the node we
are replicating from anymore or if we need to upgrade postgres to a newer major
version.

In staging we are using wal-g to retrieve the initial base-backup and WAL files
from GCS and then Postgres is automatically switching over to streaming
replication (see recovery.conf). As of writing,
`geo-secondary-01-sv-gstg.c.gitlab-staging-1.internal` is streaming from
`patroni-05-db-gstg.c.gitlab-staging-1.internal`.

* `systemctl stop chef-client`
* `gitlab-ctl stop`
* `gitlab-rake geo:db:drop`
* make backup of PGDATA conf files (wal-g will not copy them from the streaming
  replica and recovery.conf is setup manually):
  * `mkdir /var/opt/gitlab/postgresql/data.bak/; cp -a /var/opt/gitlab/postgresql/data/*.conf /var/opt/gitlab/postgresql/data.bak/`
* make sure postgresql.conf matches primary config (`max_connections` needs to be the same)
* Find the most recent db backup in GCS:

  ```
  cd /tmp/; sudo -u gitlab-psql envdir /etc/wal-g.d/env /opt/wal-g/bin/wal-g backup-list
  name                          last_modified        wal_segment_backup_start
  base_0000000900004B95000000FC 2020-07-07T14:51:36Z 0000000900004B95000000FC
  base_0000000900004B96000000DB 2020-07-07T16:43:26Z 0000000900004B96000000DB
   ```

  Take the newest backup, but make sure that the name really contains the
  highest segment number - the modification date might not be reliable in case
  there are GCS life cycle policies involved...
  The older the backup we take, the more WAL files need to be replayed later.

   The first column, "name", is what you'll want to copy for later.

* `rm -rf /var/opt/gitlab/postgresql/data/*`
* move old data away:

  ```
  mv /var/opt/gitlab/git-data/repositories /var/opt/gitlab/git-data/repositories.old
  mkdir -p /var/opt/gitlab/git-data/repositories
  chown git:git /var/opt/gitlab/git-data/repositories

  mv /var/opt/gitlab/gitlab-rails/shared /var/opt/gitlab/gitlab-rails/shared.old
  mkdir -p /var/opt/gitlab/gitlab-rails/shared
  chown git:gitlab-www /var/opt/gitlab/gitlab-rails/shared

  mv /var/opt/gitlab/gitlab-rails/uploads /var/opt/gitlab/gitlab-rails/uploads.old
  mkdir -p /var/opt/gitlab/gitlab-rails/uploads
  chown git /var/opt/gitlab/gitlab-rails/uploads
  ```

* Only in case you want to upgrade the major postgres version or gitlab-ee:
  * Re-Install gitlab-ee manually: `dpkg -r gitlab-ee && apt-get -y install gitlab-ee=13.2....`
    * take the same version as found in staging; run `dpkg -l gitlab-ee` on
    `api-01-sv-gstg.c.gitlab-staging-1.internal` to find the right version
  * `gitlab-ctl reconfigure`
  * `gitlab-ctl stop`
  * Clean up current PGDATA again: `rm -rf /var/opt/gitlab/postgresql/data/*`
* In a tmux: 
  * `cd /tmp; sudo -u gitlab-psql PGHOST=/var/opt/gitlab/postgresql /usr/bin/envdir /etc/wal-g.d/env /opt/wal-g/bin/wal-g backup-fetch /var/opt/gitlab/postgresql/data base_00000...`
    * take the backup name found above; this might take 20m or so to finish
* restore recovery.conf: `cp -a /var/opt/gitlab/postgresql/data.bak/recovery.conf /var/opt/gitlab/postgresql/data/`
  * it should look like this:

   ```
   standby_mode = 'on'
   restore_command = '/usr/bin/envdir /etc/wal-g.d/env /opt/wal-g/bin/wal-g wal-fetch "%f" "%p"'
   recovery_target_timeline = 'latest'

   # Omit this setting if not using streaming replication and relying solely on
   # archive recovery.
   primary_conninfo = 'user=gitlab-replicator password=<password> host=<target> port=5432 sslmode=prefer application_name=<output of hostname -f>'
   ```

   Target should be the IP of a replica node in the main postgres cluster,
   patroni-tagged "nofailover,noloadbalance". This should have already been set
   up in advance, and the tags can be examined by the chef attribute
   `gitlab-patroni.patroni.conf.tags`.

   The password can be obtained from the recovery.conf file on this replica.

   `chown` it to `gitlab-psql:gitlab-psql` and `chmod` it to `600`.

* `gitlab-ctl reconfigure`
  * This will cause postgres to start at some point, and you will see the
    message "psql: FATAL:  the database system is starting up" repeated for some
    time. This might cause the reconfigure operation to time out. If this
    happens, periodically try to connect to postgres (`gitlab-psql`) to know
    when it has completed the crash recovery phase or check
    `/var/log/gitlab/postgresql/current`, and reconfigure again.
* Read `/var/log/gitlab/postgresql/current` and check for errors.
* `gitlab-ctl start`
* `curl localhost:9187/metrics`. If it hangs, `sv restart postgres_exporter`
* `systemctl start chef-client`
* Check the [replication
  lag](https://thanos-query.ops.gitlab.net/graph?g0.range_input=2h&g0.max_source_resolution=0s&g0.expr=pg_replication_lag%7Benv%3D%22gstg%22%2Cfqdn%3D%22geo-secondary-01-sv-gstg.c.gitlab-staging-1.internal%22%7D&g0.tab=0)
  for this node. As long as it is generally decreasing over time, archive
  recovery is working.
* Once the replication lag is near zero, the geo postgres should switch to using
  streaming replication rather than archive recovery. You can check this is
  working by `sudo gitlab-psql -c "select * from pg_stat_replication;"`.  You
  should see `state = 'streaming'`.
* Setup foreign tables and log cursor (see [handbook](https://docs.gitlab.com/ee/administration/geo/replication/troubleshooting.html#resetting-geo-secondary-node-replication))
  * `sudo gitlab-rake geo:db:setup`
  * `sudo gitlab-rake gitlab:geo:check`
  * `sudo gitlab-rake geo:status`
  * `sudo gitlab-rake geo:db:refresh_foreign_tables`
  * `sudo gitlab-ctl hup puma`
  * `sudo gitlab-ctl restart sidekiq`
  * `sudo gitlab-ctl restart geo-logcursor`
* Check https://staging.gitlab.com/admin/geo/nodes for status

## Setup replication for a patroni-managed cluster

These directions are for setting up archive recovery in geo environments
containing a patroni-managed postgres cluster, external to the GitLab service.

Geo patroni cluster is a standby cluster replicating from production via wal
archive. If the replication is broken we will have to resetup replication for
the entire cluster following below steps:

1. Stop patroni:

    ```sh
    knife ssh roles:dr-base-db-patroni 'sudo systemctl stop patroni'
    knife ssh roles:dr-base-db-patroni 'consul kv delete -recurse service/pg-ha-cluster'
    ```

2. Backup config files and delete data directory. We need to backup config files
   because we will use wal-e backups from production to restore the data
   directory, however wal-e backups does not contain config files. We will have
   to copy the backed up config files back to data directory after restore:

    ```sh
    knife ssh roles:dr-base-db-patroni 'sudo cp /var/opt/gitlab/postgresql/data/pg_hba.conf /var/opt/gitlab/postgresql/pg_hba.conf.$(date +%F)'
    knife ssh roles:dr-base-db-patroni 'sudo cp /var/opt/gitlab/postgresql/data/pg_ident.conf /var/opt/gitlab/postgresql/pg_ident.conf.$(date +%F)'
    knife ssh roles:dr-base-db-patroni 'sudo rm -rf /var/opt/gitlab/postgresql/data' # TAKE CARE!
    knife ssh roles:dr-base-db-patroni 'sudo mkdir /var/opt/gitlab/postgresql/data'
    knife ssh roles:dr-base-db-patroni 'sudo chown gitlab-psql:gitlab-psql /var/opt/gitlab/postgresql/data'
    ```

3. Check the latest production backup is available from any node. Make sure the
   latest `wal_segment_backup_start` is within 24hrs. If not, report to DBRE
   because production backup is breaking.

    ```sh
    /usr/bin/envdir /etc/wal-g.d/env /opt/wal-g/bin/wal-g backup-list

    name	last_modified	expanded_size_bytes	wal_segment_backup_start	wal_segment_offset_backup_start	wal_segment_backup_stop	wal_segment_offset_backup_stop
    base_000000140001047600000023_02614680	2019-06-15 04:27:42.235000+00:00		000000140001047600000023	02614680
    base_00000014000104FA000000C1_07405208	2019-06-17 08:21:45.506000+00:00		00000014000104FA000000C1	07405208
    base_0000001400010883000000AB_14587176	2019-06-22 06:52:57.460000+00:00		0000001400010883000000AB	14587176
    base_00000014000109D40000008E_00851408	2019-06-25 08:16:19.988000+00:00		00000014000109D40000008E	00851408
    base_0000001400010A8C000000E8_13030128	2019-06-26 04:45:10.121000+00:00		0000001400010A8C000000E8	13030128
    base_0000001400010B4C0000008B_12535584	2019-06-27 07:24:35.529000+00:00		0000001400010B4C0000008B	12535584
    ```

4. Start patroni in one of the node. This node will likely become the leader
   node after the restore. Here we choose 01 node as the leader node.

    ```sh
    ssh patroni-01-db-dr.c.gitlab-dr.internal
    sudo su
    systemctl start patroni
    ```

5. Check patroni log to make sure it started patroni and is restoring from
   production. If for any reason the patroni is not started, try steps in step
   1.

    ```sh
    tail -f /var/log/gitlab/patroni/patroni.log
    ```

6. While 01 node is restoring, we can start manually restoring 02 and 03 node in
   parallel to speed up the process. Repeat below steps in both 02 and 03 nodes.
   The restore process will take several hours, please consider using tmux
   session to execute the restore command in line 3.

    ```sh
    ssh patroni-02-db-dr.c.gitlab-dr.internal
    sudo su - gitlab-psql
    /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e backup-fetch /var/opt/gitlab/postgresql/data LATEST
    ```

7. While the restore is in process, copy back the config files we took at step 2
   to make sure Postgresql service can start properly after the restore.

   ```sh
   knife ssh roles:dr-base-db-patroni 'sudo cp /var/opt/gitlab/postgresql/pg_hba.conf.$(date +%F) /var/opt/gitlab/postgresql/data/pg_hba.conf'
   knife ssh roles:dr-base-db-patroni 'sudo cp /var/opt/gitlab/postgresql/pg_ident.conf.$(date +%F) /var/opt/gitlab/postgresql/data/pg_ident.conf'
   ```

8. Start patroni service on 02 and 03 nodes after the restore is completed.

   ```8sh
   systemctl start patroni
   ```

8. Now the patroni cluster should be established

   ```
   gitlab-patronictl list
   +---------------+---------------------------------------+--------------+--------+---------+----+-----------+
   |    Cluster    |                 Member                |     Host     |  Role  |  State  | TL | Lag in MB |
   +---------------+---------------------------------------+--------------+--------+---------+----+-----------+
   | pg-ha-cluster | patroni-01-db-dr.c.gitlab-dr.internal | 10.251.9.101 | Leader | running | 20 |         0 |
   | pg-ha-cluster | patroni-02-db-dr.c.gitlab-dr.internal | 10.251.9.102 |        | running | 20 |        xxx   |
   | pg-ha-cluster | patroni-03-db-dr.c.gitlab-dr.internal | 10.251.9.103 |        | running | 20 |      xxx     |
   +---------------+---------------------------------------+--------------+--------+---------+----+-----------+
   ```

9. You may notice the non-leader nodes still have very large replication lags.
   The reason is that all nodes (including the leader) must replay all the wal
   archive files from the time the backup was taken till the current time. This
   replay process would take several hours.

   During the replay process, the leader node may run out of disk spaces due to
   inactive replication slots because the replica nodes are not caught up yet.

   We can stop and restart patroni services on the **replica** nodes (don't do
   it on the leader node!) every 2-4 hours to let the leader node clean up
   spaces itself.  You can do it manually, or setup temporary cron jobs to do it
   like below (don't forget to remove these jobs after the replication is caught
   up!):

   ```
   crontab -l
   0 0/2 * * * /bin/systemctl stop patroni
   10 0/2 * * * /bin/systemctl start patroni
   ```

### Related

See [patroni management](patroni-management.md) for other patroni related management operations.

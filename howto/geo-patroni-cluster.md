# Geo Patroni Cluster Management

## Setup replication for a single node

These directions are for setting up archive recovery in geo environments
containing a "main" VM running most GitLab services, including postgres. The
database here is a singleton and not managed by patroni.

1. `systemctl stop chef-client.service`
1. `gitlab-ctl stop postgresql`, or alternatively `gitlab-ctl stop` to stop all
   omnibus services.
1. See step 2 in the cluster instructions below to back up config files if need
   be, although if this is a fresh node there is no need for this.
1. Find the most recent backup:

   ```
   $ envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e backup-list

   wal_e.main   INFO     MSG: starting WAL-E
          DETAIL: The subcommand is "backup-list".
          STRUCTURED: time=2019-12-20T09:42:24.993615-00 pid=1199
   name    last_modified   expanded_size_bytes     wal_segment_backup_start        wal_segment_offset_backup_start wal_segment_backup_stop wal_segment_offset_backup_stop
   base_00000074000041BD000000AD_03738656  2019-12-15 01:44:25.762000+00:00                00000074000041BD000000AD        03738656
   base_00000074000041C700000018_10584456  2019-12-16 01:37:44.733000+00:00                00000074000041C700000018        10584456
   base_00000074000041CE000000A0_00000040  2019-12-17 00:31:07.808000+00:00                00000074000041CE000000A0        00000040
   base_00000074000041D400000094_00000040  2019-12-18 00:31:57.933000+00:00                00000074000041D400000094        00000040
   base_00000074000041DA00000080_00000040  2019-12-19 00:28:18.409000+00:00                00000074000041DA00000080        00000040
   base_00000074000041E00000003D_00000040  2019-12-20 00:30:09.775000+00:00                00000074000041E00000003D        00000040
   ```

   The backups are sorted in chronological order, newest last. Check the date to
   make sure it's actually from today, otherwise that indicates backups are
   failing and we have a problem.

   The first column, "name", is what you'll want to copy for later.

1. `rm -rf /var/opt/gitlab/postgresql/data`
1. `mkdir /var/opt/gitlab/postgresql/data`
1. `chown gitlab-psql:gitlab-psql /var/opt/gitlab/postgresql/data`
1. `chmod 700 /var/opt/gitlab/postgresql/data`
1. In a tmux: `sudo -u gitlab-psql PGHOST=/var/opt/gitlab/postgresql PATH=/opt/gitlab/embedded/bin:/opt/gitlab/embedded/sbin:$PATH /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e backup-fetch /var/opt/gitlab/postgresql/data <name of most recent backup>`
1. Create recovery.conf in the data directory:

   ```
   standby_mode = 'on'
   restore_command = '/usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e wal-fetch "%f" "%p"'
   recovery_target_timeline = 'latest'
   ```

1. `gitlab-ctl reconfigure`. This will cause postgres to start at some point,
   and you will see the message "psql: FATAL:  the database system is starting
   up" repeated for some time. This might cause the reconfigure operation to
   time out. If this happens, periodically try to connect to postgres
   (`gitlab-psql`) to know when it has completed the crash recovery phase, and
   reconfigure again.
1. Read /var/log/gitlab/postgresql/current and check for errors.
1. If you stopped all services earlier, run `gitlab-ctl start`.
1. `curl localhost:9187/metrics`. If it hangs, `sv restart postgres_exporter`
1. `systemctl start chef-client.service`
1. Check metrics for pg_replication_lag for this node. As long as it is
   generally decreasing over time, archive recovery is working.

## Setup replication for a patroni-managed cluster

These directions are for setting up archive recovery in geo environments
containing a patroni-managed postgres cluster, external to the GitLab service.

Geo patroni cluster is a standby cluster replicating from production via wal archive. If the replication is broken we will have to resetup replication for the entire cluster following below steps:

1. Stop patroni:

    ```sh
    knife ssh roles:dr-base-db-patroni 'sudo systemctl stop patroni'
    knife ssh roles:dr-base-db-patroni 'consul kv delete -recurse service/pg-ha-cluster'
    ```

2. Backup config files and delete data directory. We need to backup config files because we will use wal-e backups from production to restore the data directory, however wal-e backups does not contain config files. We will have to copy the backed up config files back to data directory after restore:

    ```sh
    knife ssh roles:dr-base-db-patroni 'sudo cp /var/opt/gitlab/postgresql/data/pg_hba.conf /var/opt/gitlab/postgresql/pg_hba.conf.$(date +%F)'
    knife ssh roles:dr-base-db-patroni 'sudo cp /var/opt/gitlab/postgresql/data/pg_ident.conf /var/opt/gitlab/postgresql/pg_ident.conf.$(date +%F)'
    knife ssh roles:dr-base-db-patroni 'sudo rm -rf /var/opt/gitlab/postgresql/data' # TAKE CARE!
    knife ssh roles:dr-base-db-patroni 'sudo mkdir /var/opt/gitlab/postgresql/data'
    knife ssh roles:dr-base-db-patroni 'sudo chown gitlab-psql:gitlab-psql /var/opt/gitlab/postgresql/data'
    ```

3. Check the latest production backup is available from any node. Make sure the latest `wal_segment_backup_start` is within 24hrs. If not, report to DBRE because production backup is breaking.

    ```sh
    /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e backup-list

    name	last_modified	expanded_size_bytes	wal_segment_backup_start	wal_segment_offset_backup_start	wal_segment_backup_stop	wal_segment_offset_backup_stop
    base_000000140001047600000023_02614680	2019-06-15 04:27:42.235000+00:00		000000140001047600000023	02614680
    base_00000014000104FA000000C1_07405208	2019-06-17 08:21:45.506000+00:00		00000014000104FA000000C1	07405208
    base_0000001400010883000000AB_14587176	2019-06-22 06:52:57.460000+00:00		0000001400010883000000AB	14587176
    base_00000014000109D40000008E_00851408	2019-06-25 08:16:19.988000+00:00		00000014000109D40000008E	00851408
    base_0000001400010A8C000000E8_13030128	2019-06-26 04:45:10.121000+00:00		0000001400010A8C000000E8	13030128
    base_0000001400010B4C0000008B_12535584	2019-06-27 07:24:35.529000+00:00		0000001400010B4C0000008B	12535584
    ```

4. Start patroni in one of the node. This node will likely become the leader node after the restore. Here we choose 01 node as the leader node.

    ```sh
    ssh patroni-01-db-dr.c.gitlab-dr.internal
    sudo su
    systemctl start patroni
    ```

5. Check patroni log to make sure it started patroni and is restoring from production. If for any reason the patroni is not started, try steps in step 1.

    ```sh
    tail -f /var/log/gitlab/patroni/patroni.log
    ```

6. While 01 node is restoring, we can start manually restoring 02 and 03 node in parallel to speed up the process. Repeat below steps in both 02 and 03 nodes. The restore process will take several hours, please consider using tmux session to execute the restore command in line 3.

    ```sh
    ssh patroni-02-db-dr.c.gitlab-dr.internal
    sudo su - gitlab-psql
    /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e backup-fetch /var/opt/gitlab/postgresql/data LATEST
    ```

7. While the restore is in process, copy back the config files we took at step 2 to make sure Postgresql service can start properly after the restore.

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

9. You may notice the non-leader nodes still have very large replication lags.  The reason is that all nodes (including the leader) must replay all the wal archive files from the time the backup was taken till the current time. This replay process would take several hours.

   During the replay process, the leader node may run out of disk spaces due to inactive replication slots because the replica nodes are not caught up yet.

   We can stop and restart patroni services on the **replica** nodes (don't do it on the leader node!) every 2-4 hours to let the leader node clean up spaces itself.  You can do it manually, or setup temporary cron jobs to do it like below (don't forget to remove these jobs after the replication is caught up!):

   ```
   crontab -l
   0 0/2 * * * /bin/systemctl stop patroni
   10 0/2 * * * /bin/systemctl start patroni
   ```

### Related

See [patroni management](patroni-management.md) for other patroni related management operations.

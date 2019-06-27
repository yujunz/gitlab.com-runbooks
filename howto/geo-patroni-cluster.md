

# Geo Patroni Cluster Management

## Setup replication for the entire cluster

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
    knife ssh roles:dr-base-db-patroni 'sudo chown gitlab-psql:gitlab-psql  /var/opt/gitlab/postgresql/data'
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



### Other patroni specific management

See [patroni management](patroni-management.md) for other patroni related management operations.


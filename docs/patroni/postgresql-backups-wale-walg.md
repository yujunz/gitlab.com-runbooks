[[_TOC_]]

# PostgreSQL Backups: WAL-E, WAL-G

## WAL-E and WAL-G Overview

[WAL-E][WAL-E] was designed by Heroku to solve their PostgreSQL backup issues. It is a Python-based application that is invoked by the PostgreSQL process via the 'archive_command' as part of PostgreSQLs [continuous archiving][PSQL_Archiving] setup.

It works by taking [Write-Ahead Logging][PSQL_WAL] files, compressing them, and then archiving them off to a storage target in near realtime. On a nightly schedule, WAL-E also pushes a full backup to the storage target, referred to as a 'base backup'. A restore then is a combination of a 'base backup' and all of the WAL transaction files since the backup to recover the database to a given point in time.

[WAL-G](https://github.com/wal-g/wal-g) is [the successor of WAL-E](https://www.citusdata.com/blog/2017/08/18/introducing-wal-g-faster-restores-for-postgres/) with a number of key differences. WAL-G uses LZ4, LZMA, or Brotli compression, multiple processors, and non-exclusive base backups for Postgres. It is backward compatible with WAL-E: it is possible to restore from a WAL-E backup using WAL-G, but not vice versa.

Currently (June 2020), the main backup tool for GitLab.com is still WAL-E, it is used to create full backups daily and to archive WALs. But to restore from such backups, WAL-G is being used, and there is work in progress to migrate to WAL-G completely (to use it for daily backups and WAL archive creation), and full migration to WAL-G is expected soon (Summer 2020). Once the migration is finished, instructions related to WAL-E become obsolete.

## Very Quick Intro: 5 Main Commands

Backups consists of two parts:
- periodical (daily) "full" backups (a.k.a "base backups"), and
- "stream" of WALs to enable Point-in-time recovery (PITR).

To restore to a given point of time or to the latest available point, a full backup and a sequence of WALs are needed. To reduce the size of such a sequence, full backups can be performed more frequently. On the other hand, creation of full backups is a very IO-intensive operation, so it doesn't make sense to do it very often. Currently, for the GitLab.com database, full backups are created daily.

Both WAL-E and WAL-G have 5 main commands:

| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Command&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Purpose | How it is executed | Details |
| :----------:     |  ------  | ------ | --------- |
| `backup-list`   | Get the list of full backups currently stored in the archive   | Manually | It is helpful to see if there are "gaps" (missing full backups).<br/> Also, based on displayed LSNs, we can calculate the amount of WALs generated per day.<br/> Notice, there is no "wal-list" – this command would print too much information so it would be hard to use it, so neither WAL-E nor WAL-G implement it. |
| `backup-push`   | Create a full backup: archive PostgreSQL data directory fully   | Manually or automatically | Daily execution is configured in a cron record (see `crontab -l` under `gitlab-psql`).<br/> At the moment, it is executed daily (at 00:00 UTC) on the primary, using WAL-E.<br/>  This operation is very IO-intensive, the expected speed: ~0.5-1 TiB/h for WAL-E, 1-2 TiB/h for WAL-G.<br/>  (*Once the migration to WAL-G is fully complete, one of secondaries will perform WAl-G's `backup-push` daily.*).   |
| `wal-push`   | Archive WALs. Each WAL is 16 MiB by default    | Automatically (`archive_command`) | This command is usually used in `archive_command` (PostgreSQL configuration parameter) and automatically executed<br/>  by PostgreSQL on the primary node. At the moment, WAL-E is used. As of June 2020, ~1.5-2 TiB of WAL files is archived each working day<br/>  (less on holidays and weekends). Once the migration to WAL-G is fully complete, the alternative WAL-G's command will be used – still on the primary,<br/>  because it disk IO caused by this action is not intensive and moving it to replicas would introduce additional delays<br/>  (hence, degradation in backup characteristics – a worse RPO, recovery point objective).   |
| <nobr>`backup-fetch`</nobr>   | Restore PostgreSQL data directory from a full backup  | Manually | Is it to executed manually a fresh restore from backups is needed. Also used in "gitlab-restore" for daily verification of backups<br/> (see https://ops.gitlab.net/gitlab-com/gl-infra/gitlab-restore/postgres-gprd/-/blob/master/bootstrap.sh).   |
| `wal-fetch`   | Get a WAL from the archive   | Automatically<br/> (`restore_command`; not used on `patroni-XX` nodes) | It is to be used in `restore_command` (see `recovery.conf` in the case of PostgreSQL 11 or older, and `postgresql.conf` for PostgreSQL 12+).<br/>  Postgres automatically uses it to fetch and replay a stream of WALs on replicas.<br/>  As of June 2020, `restore_command` is NOT configured on production and staging instances – we use only streaming replication there. However, in the future, it may change.<br/>  Two "special" replicas, "archive" and "delayed", do not use streaming replication – instead, they rely on fetching WALs from the archive, therefore, they have `wal-fetch` present in `restore_command`. |

## Backing Our Data Up

### Where is Our Data Going

Currently, our production data is being pushed using WAL-E to Google Cloud Storage into a bucket labeled [`gitlab-gprd-postgres-backup`](https://console.cloud.google.com/storage/browser/gitlab-gprd-postgres-backup).
All servers of an environment (like `gprd`) push their WAL to the same bucket location. This is because, in the event of a failover, all the servers should have the same backup location to streamline both backups and restores. With WAL-E, secondary servers do not push WAL files or base backups, so they do not interfere. However, some replicas retrieve WALs from the bucket for archive recovery.

The GCS bucket is configured with multi-regional storage (US location).

Our secondary databases (version, customers, sentry, etc.) are still in AWS S3 in a bucket labeled `gitlab-secondarydb-backups`. The data is being encrypted with GPG. The key can be found in the Production vault of 1Password. <!-- Nik: This seems very doubtful to me, should be verified. There are rumors that "version" and "customers" are in Cloud SQL but I didn't manage to see them there -->

GitLab.com production database archive is located in the bucket `gitlab-gprd-postgres-backup` in GCS, in the folder `pitr-wale-pg11`. Note that WAL-E uses path with two slashes, so in GCP Console, you might need to modify the URL to see the folder (`gitlab-gprd-postgres-backup//pitr-wale-pg11`). Similarly, use two slashes when using `gsutil`:

```bash
gsutil ls -L gs://gitlab-gprd-postgres-backup//pitr-wale-pg11/
```

<!-- Nik: TODO: decribe the new location -- for WAL-G backups – when the migration to WAL-G is done-->

### Interval and Retention

We currently take a basebackup each day at 0 am UTC and continuously stream WAL data to GCS. As of June 2020, the daily backup process performed by WAL-E takes ~9 hours with Postgres cluster size ~7 TiB.

Backups are kept for 14 days and cleaned up by a lifecycle rule on GCS. <!-- Nik 2020-06-21 TODO: this may have changed recently, double-check it, see https://gitlab.com/gitlab-com/gl-infra/production/-/issues/2297#note_364350097  -->

### How Does it Get There?

#### Production

##### Daily basebackup

WAL-E on production is set up via the gitlab_wale cookbook. This cookbook installs all of the relevant python packages and installs a cronjob to create base_backups. The relevant cron command and settings are set via attributes on the chef roles.

```cron
# Chef Name: full wal-e backup
0 0 * * * /opt/wal-e/bin/backup.sh >> /var/log/wal-e/wal-e_backup_push.log 2>&1
```

##### Archiving WALs

WAL files are sent via PostgreSQL's `archive_command` parameter, which looks something like the following:

```
archive_command = /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e --gpg-key-id 66B9829C wal-push %p
```

### How Do I Verify This?

You can always check the GCS storage bucket, or you can check the logs of the PostgreSQL server:

```bash
root@db1:~# tail -f /var/log/gitlab/postgresql/postgresql.log
2018-11-15_12:39:13.91682         DETAIL: Archiving to "gs://gitlab-gprd-postgres-backup/pitr-wale-v1/wal_005/00000006000096F30000006A.lzo" complete at 10986.4KiB/s.
2018-11-15_12:39:13.91682         STRUCTURED: time=2018-11-15T12:39:13.916366-00 pid=41960 action=push-wal key=gs://gitlab-gprd-postgres-backup/pitr-wale-v1/wal_005/00000006000096F30000006A.lzo prefix=pitr-wale-v1/ rate=10986.4 seg=00000006000096F30000006A state=complete
2018-11-15_12:39:13.95760 wal_e.worker.upload INFO     MSG: completed archiving to a file
```

> See also: [How to check if WAL-E/WAL-G backups are running](./backups-check-if-running.md).

## Restoring Data

### Oh Sh*t, I Need to Get It BACK!

Before we start, take a deep breath and don't panic.

#### Production

Consider using the delayed replica to speed up PITR. The full database backup restore is also automated in a [CI pipeline](https://gitlab.com/gitlab-restore/postgres-gprd), which may be helpful depending on the type of disaster. To restore from WAL-E backups, either WAL-G or WAL-E can be used. In "gitlab-restore", the default is WAL-G, as it gives 3-4 times better restoration speed than WAL-E. Use `WAL_E_OR_WAL_G` CI variable to switch to WAL-E if needed (just set this variable to `wal-e`). For the "basebackup" phase of the restore process, on an `n1-standard-16` instance, the expected speed of filling the PGDATA directory is 0.5-1 TiB per hour for WAL-E and 1.5-2 TiB per hour for WAL-G.

Below we describe the restore process step by step for the case of WAL-E (old procedure). For WAL-G, it is very similar, with a couple of nuances. For details, please see https://ops.gitlab.net/gitlab-com/gl-infra/gitlab-restore/postgres-gprd/blob/master/bootstrap.sh.

In order to restore, the following steps should be performed. It is assumed that you have already set up the new server, and that server is configured with our current chef configuration.

1. Log in to the `gitlab-psql` user (`su - gitlab-psql`)

1. Create restore.conf file: <!-- Nik: TODO: review and fix this, this is very outdated -->

    ```bash
    cat > /var/opt/gitlab/postgresql/data/recovery.conf <<RECOVERY
    restore_command = '/usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e wal-fetch -p 4 "%f" "%p"'
    recovery_target_timeline = 'latest'
    RECOVERY
    chown gitlab-psql:gitlab-psql/var/opt/gitlab/postgresql/data/recovery.conf
    ```

1. Restore the base backup (run in a screen on tmux session and be ready to wait several hours):

    ```bash
    /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e backup-list
    PGHOST=/var/opt/gitlab/postgresql/ PATH=/opt/gitlab/embedded/bin:/opt/gitlab/embedded/sbin:$PATH \
      /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e backup-fetch /var/opt/gitlab/postgresql/data <backup name from backup-list command>
    ```

    To restore latest backup you can use the following:
    ```bash
    /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e backup-list
    PGHOST=/var/opt/gitlab/postgresql/ PATH=/opt/gitlab/embedded/bin:/opt/gitlab/embedded/sbin:$PATH /usr/bin/envdir \
      /etc/wal-e.d/env /opt/wal-e/bin/wal-e backup-fetch /var/opt/gitlab/postgresql/data LATEST
    ```

1. This command will output nothing if it is successful.

1. Optional: In case the database should only be recovered to a certain point-in-time, add [recovery target settings](https://www.postgresql.org/docs/9.6/recovery-target-settings.html) to `recovery.conf`.

1. Start PostgreSQL. This will begin the archive recovery. You can watch the progress in the postgres log.

1. IMPORTANT:
    - WAL-G won't stores the PostgreSQL configuration (postgresql.conf, postgresql.auto.conf, recovery.conf). You need to take care about configuration separately.
    - As of June 2020, `restore_command` is not used on `patroni-XX` nodes. Therefore, if your restoration is happening as a part of DR, you need to consider removing `restore_command` in the very end.
    - If this is your new master (again, if it is DR actions), then you need to promote it (using `/var/opt/gitlab/postgresql/trigger` or `pg_ctl promote`), and adjust configuration (`archive_command`, `restore_command`).


## Troubleshooting: How to Check if WAL-E Backups are Running

WAL-E is running on all machines in the patroni cluster. However, backups are actually happening only from the master. In order to find out which machine is the master, go to the [relevant Grafana dashboard](https://dashboards.gitlab.net/d/000000244/postgresql-replication-overview?orgId=1).

`wal-push` logs can be observed in syslog (`sudo journalctl -f`, Kibana).

`backup-push` logs you can check wale logs in two ways:
1. using Kibana (bear in mind that there were cases in the past when logs where not shipped): <!-- NS: doubtful, TODO: double check it; update once https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10499 is done-->
  - [`log.gprd.gitlab.net`](https://log.gprd.gitlab.net)
  - index: `pubsub-system-inf-gprd`
  - document field: `json.ident` with value `wal_e*`
2. by logging directly into the VM:
  - ssh to the patroni master
  - logs are located in `/var/log/wal-e/wal-e_backup_push.log`, the file is under rotation, so check also `/var/log/wal-e/wal-e_backup_push.log.1`, etc
  - alternatively, see syslog `/var/log/syslog`, look for `wal\_e.worker.upload` (or `sudo journalctl --since yesterday | grep "worker.upload"` to see activity for yesterday and today)

`wal-push`: example of a log entry on the primary working correctly:
```
2019-06-07_16:50:42 patroni-04-db-gprd wal_e.worker.upload  INFO     MSG: begin archiving a file#012        DETAIL: Uploading "pg_xlog/000000140001003100000077" to "gs://gitlab-gprd-postgres-backup/pitr-wale-v1/wal_005/000000140001003100000077.lzo".#012        STRUCTURED: time=2019-06-07T16:50:42.145335-00 pid=35067 action=push-wal key=gs://gitlab-gprd-postgres-backup/pitr-wale-v1/wal_005/000000140001003100000077.lzo prefix=pitr-wale-v1/ seg=000000140001003100000077 state=begin
```

`backup-push`: example of log entries on a replica working correctly (no backups are actually happening from replicas):
```
2019-06-07_00:00:03 patroni-01-db-gprd wal_e.main    INFO     MSG: starting WAL-E#012        DETAIL: The subcommand is "backup-push".#012        STRUCTURED: time=2019-06-07T00:00:03.077171-00 pid=37922
2019-06-07_00:00:05 patroni-01-db-gprd wal_e.operator.backup  WARNING  MSG: blocking on sending WAL segments#012        DETAIL: The backup was not completed successfully, but we have to wait anyway.  See README: TODO about pg_cancel_backup#012        STRUCTURED: time=2019-06-07T00:00:05.263203-00 pid=37922
2019-06-07_00:00:05 patroni-01-db-gprd wal_e.main    ERROR    MSG: Could not stop hot backup#012        STRUCTURED: time=2019-06-07T00:00:05.296652-00 pid=37922
```

### WAL-E's `wal-push` is not working

#### WAL-E `wal-push` process stuck ####

WAL-E works by uploading files to a GCS bucket every few seconds. The upload is done by a forked process which lives only a few seconds. For each successful upload there should be log entries similar to this:
```
2019-10-03_12:07:33 patroni-02-db-gprd wal_e.worker.upload  INFO     MSG: begin archiving a file#012        DETAIL: Uploading "pg_xlog/0000001D00014F69000000E7" to "gs://gitlab-gprd-postgres-backup/pitr-wale-v1/wal_005/0000001D00014F69000000E7.lzo".#012        STRUCTURED: t
ime=2019-10-03T12:07:33.719239-00 pid=20408 action=push-wal key=gs://gitlab-gprd-postgres-backup/pitr-wale-v1/wal_005/0000001D00014F69000000E7.lzo prefix=pitr-wale-v1/ seg=0000001D00014F69000000E7 state=begin
2019-10-03_12:07:34 patroni-02-db-gprd wal_e.worker.upload  INFO     MSG: completed archiving to a file#012        DETAIL: Archiving to "gs://gitlab-gprd-postgres-backup/pitr-wale-v1/wal_005/0000001D00014F69000000E7.lzo" complete at 14281KiB/s.#012        STRUCTURED: time=2
019-10-03T12:07:34.439057-00 pid=20408 action=push-wal key=gs://gitlab-gprd-postgres-backup/pitr-wale-v1/wal_005/0000001D00014F69000000E7.lzo prefix=pitr-wale-v1/ rate=14281 seg=0000001D00014F69000000E7 state=complete
```

If you're not seeing logs like this (e.g. nothing writes to the log file or there are only entries with `state=begin` but not with `state=complete`) then there's something wrong with WAL-E.

##### Check the WAL-E's `wal-push` upload process

Run `ps` a few times (the upload process is short-lived so you might not catch it the first time), example output:
```
# ps aux | grep 'wal-push'
gitlab-+ 29632  0.0  0.0   4500   844 ?        S    12:16   0:00 sh -c /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e wal-push pg_xlog/0000001D00014F6B000000A2
gitlab-+ 29633 35.0  0.0 124200 41488 ?        D    12:16   0:00 /opt/wal-e/bin/python /opt/wal-e/bin/wal-e wal-push pg_xlog/0000001D00014F6B000000A2
root     29638  0.0  0.0  12940   920 pts/0    S+   12:16   0:00 grep wal-push
```

If the timestamp on the WAL-E process is relatively long time in the past (e.g. 15 mins, 1h) then that's a hint that it's stuck at uploading files.

Check the state of the process with: `strace -p <pid>` . If the process is stuck, `strace` will show no activity.

Another indicator of a stuck process is the timestamp on the latest file uploaded to GCS, i.e. it will be close to the timestamp on the upload process. `gsutil` might take too long to list files in the bucket, so go to the [web UI](https://console.cloud.google.com/storage/browser/gitlab-gprd-postgres-backup/) and start typing in the prefix of the filename last uploaded (don't type in the full name).

If everything points to the fact that WAL-E upload process is stuck, consider killing it. BE EXTREMELY CAREFUL! After killing the process it should be restarted automatically and the backups should resume immediately.

#### Other ####

If WAL-E is not working, it will probably be something related with the network or S3.

PostgreSQL is configured to archive to WAL-E upon some conditions, as specified via Chef:
```
    gitlab_rb:
      postgresql:
        archive_command:              /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e wal-push %p
```

### WAL-E is working (but I still got paged)

The problem might be `mtail`.

1. Check `mtail` is working with `sudo sv status mtail`
1. If `mtail` is up, check `/var/log/mtail` for errors under `/var/log/mtail.ERROR`.
1. You might want to restart `mtail` if it's stuck with `sudo sv restart mtail`.


## Database Backups Restore Testing

Backups restore testing is fully automated, see https://ops.gitlab.net/gitlab-com/gl-infra/gitlab-restore/postgres-gprd/. Backups of production GitLab.com backup are tested twice per day:

1. Slightly after the time when `backup-push` is expected to be finished on the primary (at 11:30 a.m. UTC as of June 2020). This verifies the fresh full backup and small addition of WALs.
1. Right after `backup-push` is invoked on the primary (at 00:05 a.m.). This allows to ensure that not only full backups are in a good state, but also WAL stream, all the WALs in the archive are OK, without gaps.

### Troubleshooting: What to Do if Backup Restore Verification Fails

In the case of failing Postgres backup verification jobs, use the following to troubleshoot:

1. In ["gitlab-restore/postgres-grpd" CI/CD pipelines](https://ops.gitlab.net/gitlab-com/gl-infra/gitlab-restore/postgres-gprd/pipelines), find the pipeline that is subject to investigation and remember its ID.
1. First, look inside the pipeline's jobs output. Sometimes the instance even hasn't been provisioned – quite often due to hitting some quotas (such as number of vCPUs or IP addresses in "gitlab-restore" project). In this case, either clean up instances that are not needed anymore or increase the quotas in GCP.
1. In ["gitlab-restore" project at GCP console](https://console.cloud.google.com/compute/instances?project=gitlab-restore), find an instance with the pipeline ID in instance name. SSH to it and check:
    - Disk space (`df -hT`). If we hit the disk space limit, it is time to increase the disk size again – usually, it's done in the [source code of the "gitlab-restore" project](https://ops.gitlab.net/gitlab-com/gl-infra/gitlab-restore/postgres-gprd), but it is also possible to configure CI/CD schedules to override it.
    - Recent logs (`sudo journalctl -f`, `sudo journalctl --since yesterday | less`). There might be some insights related to, say, WAL-E/WAL-G failures.
    - Postgres replica is working (`sudo gitlab-psql`). If you cannot connect, then either Postgres is not installed properly, or it hasn't reached the point when PGDATA can be considered consistent. If the replaying of WALs is still happening (see the logs), then it is worth waiting some time. Otherwise, the logs should be carefully investigated.
1. Finally, if none of above items revealed any issues, try performing `backup-fetch` manually. For that:
    1. Run a new CI/CD pipeline in "gitlab-restore", using the CI variable values taking them from "Schedules" section (there is "Reveal" button there), and adding `NO_CLEANUP = 1` to preserve the instance.
    1. SSH to the instance after a few minutes, when it's up and running.
    1. Before proceeding, use WAL-E's (WAL-G's) `backup-list` to see the available backups. One of possible reasons of failure is lack of some daily basebackup. In such a case, you need to so to Postgres master node and analyze WAL-E (WAL-G) log (check `sudo -u postgres crontab -l`, it should show how daily basebackups are triggered and where the logs are located). If the list of backups looks right, continue troubleshooting.
    1. Wait until the issue repeats and backup verification fails (assuming it's permament – if not, we only can analyze the logs of the previous runs).
    1. Manually follow the steps from https://ops.gitlab.net/gitlab-com/gl-infra/gitlab-restore/postgres-gprd/blob/master/bootstrap.sh, starting from erasing PGDATA directory and proceedign to WAL-E's (WAL-G's) `backup-fetch` step which normally takes a few hours.
    1. Once `backup-fetch` is finished, you should have a Postgres "archive replica" – a Postgres instance that constantly pulls new WAL data from WAL-E (WAL-G) archive. Check it with `sudo gitlab-psql`. Note, that it is normal if you cannot connect during some period of time and see `FATAL: the database system is starting up` error: until recovery mode is reached a consistent point, Postgres performs REDO and doesn't allow connections. It may take some time (minutes, dozens of minutes), after which you should be able to connect and observe how the database state is constantly changing due to receving (via `wal-fetch`) and replaying new WALs. To see that, use either `select pg_last_xact_replay_timestamp()` or `select now(), created_at, now() - created_at from issues order by id desc limit 1`.
    1. Troubleshoot any failures in place, checking the logs, free disk space and so on.
    1. Finally, once troubleshooting is done, do not forget to destroy the instance manually, it won't get destroyed automatically because of `NO_CLEANUP = 1` we have used!

# Further Read

- [Continuous Archiving and Point-in-Time Recovery (PITR)](https://www.postgresql.org/docs/current/continuous-archiving.html) (PostgreSQL official documentation)
- [Backup Control Functions](https://www.postgresql.org/docs/current/functions-admin.html#FUNCTIONS-ADMIN-BACKUP) (PostgreSQL official documentation)
- [WAL Internals](https://www.postgresql.org/docs/current/wal-internals.html) (PostgreSQL official documentation)
- [Write Ahead Logging — WAL](http://www.interdb.jp/pg/pgsql09.html) (The Internals of PostgreSQL)
- [Understanding WAL nomenclature](https://eulerto.blogspot.com/2011/11/understanding-wal-nomenclature.html) (Euler Taveira)
- [What does pg_start_backup() do?](https://www.2ndquadrant.com/en/blog/what-does-pg_start_backup-do/) (2nd Quadrant)

[Wal-E]: https://github.com/wal-e/wal-e
[PSQL_Archiving]: https://www.postgresql.org/docs/9.6/static/continuous-archiving.html
[PSQL_WAL]: https://www.postgresql.org/docs/current/static/wal-intro.html

[[_TOC_]]

# PostgreSQL Backups: WAL-E, WAL-G

## Wal-E and WAL-G Overview

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

| Command&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Purpose | How it is executed | Details |
| ----------     |  ------  | :------: | --------- |
| `backup-list`   | Get the list of full backups currently stored in the archive   | Manually | It is helpful to see if there are "gaps" (missing full backups).<br/> Also, based on displayed LSNs, we can calculate the amount of WALs generated per day.<br/> Notice, there is no "wal-list" – this command would print too much information so it would be hard to use it, so neither WAL-E nor WAL-G implement it. |
| `backup-push`   | Create a full backup: archive PostgreSQL data directory fully   | Manually or automatically | Daily execution is configured in a cron record (see `crontab -l` under `gitlab-psql`).<br/> At the moment, it is executed daily (at 00:00 UTC) on the primary, using WAL-E.<br/>  This operation is very IO-intensive, the expected speed: ~0.5-1 TiB/h for WAL-E, 1-2 TiB/h for WAL-G.<br/>  (*Once the migration to WAL-G is fully complete, one of secondaries will perform WAl-G's `backup-push` daily.*).   |
| `wal-push`   | Archive WALs. Each WAL is 16 MiB by default    | Automatically (`archive_command`) | This command is usually used in `archive_command` (PostgreSQL configuration parameter) and automatically executed<br/>  by PostgreSQL on the primary node. At the moment, WAL-E is used. As of June 2020, ~1.5-2 TiB of WAL files is archived each working day<br/>  (less on holidays and weekends). Once the migration to WAL-G is fully complete, the alternative WAL-G's command will be used – still on the primary,<br/>  because it disk IO caused by this action is not intensive and moving it to replicas would introduce additional delays<br/>  (hence, degradation in backup characteristics – a worse RPO, recovery point objective).   |
| <nobr>`backup-fetch`</nobr>   | Restore PostgreSQL data directory from a full backup  | Manually | Is it to executed manually a fresh restore from backups is needed. Also used in "gitlab-restore" for daily verification of backups<br/> (see https://ops.gitlab.net/gitlab-com/gl-infra/gitlab-restore/postgres-gprd/-/blob/master/bootstrap.sh).   |
| `wal-push`   | Get a WAL from the archive   | Automatically<br/> (`restore_command`; not used on `patroni-XX` nodes) | It is to be used in `restore_command` (see `recovery.conf` in the case of PostgreSQL 11 or older, and `postgresql.conf` for PostgreSQL 12+).<br/>  Postgres automatically uses it to fetch and replay a stream of WALs on replicas.<br/>  As of June 2020, `restore_command` is not configured on production and staging instances – we use only streaming replication there. However, in the future, it may change.<br/>  Two "special" replicas, "archive" and "delayed", do not use streaming replication – instead, they rely on fetching WALs from the archive, therefore, they have `wal-fetch` present in `restore_command`. |

## Backing Our Data Up

### Where is Our Data Going

Currently, our production data is being pushed using WAL-E to Google Cloud Storage into a bucket labeled [`gitlab-gprd-postgres-backup`](https://console.cloud.google.com/storage/browser/gitlab-gprd-postgres-backup).
All servers of an environment (like `gprd`) push their WAL to the same bucket location. This is because, in the event of a failover, all the servers should have the same backup location to streamline both backups and restores. With WAL-E, secondary servers do not push WAL files or base backups, so they do not interfere. However, some replicas retrieve WALs from the bucket for archive recovery.

The GCS bucket is configured with multi-regional storage (US location).

Our secondary databases (version, customers, sentry, etc.) are still in AWS S3 in a bucket labeled `gitlab-secondarydb-backups`. The data is being encrypted with GPG. The key can be found in the Production vault of 1Password. <!-- Nik: This seems very doubtful to me, should be verified. There are rumors that "version" and "customers" are in Cloud SQL but I didn't manage to see them there -->

<!-- Nik: TODO: decribe the new location -- WAL-E backups after migration to Postgres 11 -->
<!-- Nik: TODO: decribe the new location -- for WAL-G backups -->

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

#### Secondary

For now, please follow the manual procedure below.

## Creating servers for testing backups

The semi-automated procedure (secondary db):
1. `mkdir ./bad && cd ./bad`
1. grab backup_scripts/02-secondary-db.sh, edit variables
1. `time bash 02-secondary-db.sh`
1. continue from customizing wal-e access keys and selecting time to restore.
    (Make sure the cloud-init finished: `tail -f /var/log/cloud-init-output.log`

The manual procedure:

1. For testing of secondary database restore, create a server of similar size to the database you are restoring. Just use the same Ubuntu version, as they have different postgresql versions, and backup from 9.5 won't install on 9.3.
1. Prepare the server:
    1. Install necessary software:

        ```bash
        # install and stop postgres
        apt-get update && apt-get -y install daemontools lzop gcc make python3 virtualenvwrapper python3-dev libssl-dev postgresql gnupg-agent pinentry-curses
        service postgresql stop

        # Configure wal-e
        mkdir -p /opt/wal-e /etc/wal-e.d/env
        virtualenv --python=python3 /opt/wal-e
        /opt/wal-e/bin/pip3 install --upgrade pip
        /opt/wal-e/bin/pip3 install boto azure wal-e
        ```

    1. `mkdir /etc/wal-e.d/env -p` and populate files `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `WALE_S3_PREFIX`, `WALE_GPG_KEY_ID`, `GPG_AGENT_INFO`
        1. `WALE_GPG_KEY_ID` should be `66B9829C`.
        1. The format of `GPG_AGENT_INFO` is `/path/to/socket:gpg-agent-pid:1`
            * For gpg version 1.4 you can run `eval $(gpg-agent --daemon)` as the postgres user. This will add `GPG_AGENT_INFO` variable to the environment for the user. You can then populate `/etc/wal-e.d/env/GPG_AGENT_INFO` with that data.
            * For gpg version 2.1 `gpg-agent` does not output anything. You will need to run `gpg-agent --daemon` as the postgres user and then construct the variable manually by looking for the socket path and pid.

1. Add GPG keys as postgres user:

    ```bash
    gpg --allow-secret-key-import --import /etc/wal-e.d/ops-contact+dbcrypt.key
    gpg --import-ownertrust /etc/wal-e.d/gpg_owner_trust
    ```

1. Enable gpg-agent in gpg.conf

    ```bash
    echo 'use-agent' > ~/.gnupg/gpg.conf
    ```

1. Add password and test secret keys. This should ask for a password and then create an encrypted file at `/tmp/test.gpg`.

    ```bash
    touch /tmp/test
    gpg --encrypt -r 66B9829C /tmp/test
    ```

1. If you have changed to the postgres user via `su`, you will need to be sure `GPG_TTY` is exported and tty device is read/write by postgres user.

    ```bash
    root$ chmod o+rw $(tty)
    postgres$ export GPG_TTY=$(tty)
    ```

1. Create restore.conf file.

    ```bash
    # precreate recovery.conf, edit the recovery target time to your desired restore time. Ensure the time is AFTER the base backup time.
    export RESTORE_PG_VER=9.5 # 9.3 in case of 14.04
    cat > /var/lib/postgresql/${RESTORE_PG_VER}/main/recovery.conf <<RECOVERY
    restore_command = '/usr/bin/envdir /etc/wal-g.d/env /opt/wal-g/bin/wal-g wal-fetch "%f" "%p"'
    recovery_target_time = '2017-XX-YY 06:00:00'
    RECOVERY
    chown postgres:postgres /var/lib/postgresql/${RESTORE_PG_VER}/main/recovery.conf
    ```

1. Restore the base backup

    ```bash
    /usr/bin/envdir /etc/wal-g.d/env /opt/wal-e/bin/wal-g backup-list
    /usr/bin/envdir /etc/wal-g.d/env /opt/wal-e/bin/wal-g backup-fetch /var/lib/postgresql/${RESTORE_PG_VER}/main <backup name from backup-list command>
    ```

    To restore from the latest backup you can use the following:

    ```bash
    /usr/bin/envdir /etc/wal-g.d/env /opt/wal-g/bin/wal-g backup-fetch /var/lib/postgresql/${RESTORE_PG_VER}/main LATEST
    ```

1. Start PostgreSQL. This will begin the point-in-time recovery to the time specified in recovery.conf. You can watch the progress in the postgres log.

# Further Read

- [How to check if WAL-E/WAL-G backups are running](./backups-check-if-running.md)
- [How to troubleshoot backup verification job failures](./backups-verification-job-failures.md)

[Wal-E]: https://github.com/wal-e/wal-e
[PSQL_Archiving]: https://www.postgresql.org/docs/9.6/static/continuous-archiving.html
[PSQL_WAL]: https://www.postgresql.org/docs/current/static/wal-intro.html

# Using Wal-E

## Wal-E Overview

[Wal-E][Wal-E] was designed by Heroku to solve their PostgreSQL backup issues. It is a python based application that is invoked by the PostgreSQL process via the 'archive_command' as part of PostgreSQLs [continuous archiving][PSQL_Archiving] setup.

It works by taking [Write-Ahead Logging][PSQL_WAL] files, compressing them, and then archiving them off to a storage target in near realtime. On a nightly schedule Wal-E also pushes a full backup to the storage target, referred to as a 'base backup'. A restore then is a combination of a 'base backup' and all of the WAL transaction files since the backup to recover the database to a given point in time.

## Backing Our Data Up

### Where is Our Data Going

Currently our production data is being pushed to Google Cloud Storage into a bucket labeled [`gitlab-gprd-postgres-backup`](https://console.cloud.google.com/storage/browser/gitlab-gprd-postgres-backup).
All servers of an environment (like `gprd`) push their WAL to the same bucket location. This is because in the event of a failover, all the servers should have the same backup location to streamline both backups and restores. Secondary servers do not push WAL files or base backups, so they do not interfere. However, some replicas retrieve WAL from the bucket for archive recovery.

The GCS bucket is configured with multi-regional storage (US location).

Our secondary databases (version, customers, sentry, etc) are still in AWS S3 in a bucket labeled `gitlab-secondarydb-backups`. The data is being encrypted with GPG. The key can be found in the Production vault of 1Password.

### Interval and Retention

We currently take a basebackup each day at 0am UTC and continuously stream WAL data to GCS. Taking a  basebackup currently takes about 3-4 hours (November 2018).

Backups are kept for 14 days and cleaned up by a lifecycle rule on GCS.

### How Does it Get There?

#### Production

WAL-E on production is set up via the gitlab_wale cookbook. This cookbook installs all of the relevant python packages and installs a cronjob to create base_backups. The relevant cron command and settings is set via attributes on the chef roles.

```cron
# Chef Name: full wal-e backup
0 2 * * * PGHOST=/var/opt/gitlab/postgresql/ PATH=/opt/gitlab/embedded/bin:/opt/gitlab/embedded/sbin:$PATH /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e backup-push /var/opt/gitlab/postgresql/data &> /tmp/wal-e_backup_push.log
```

#### Secondary Servers

Cronjobs for taking base backups are added to the postgres user via chef. They are as follows:

```cron
# Chef Name: full wal-e backup
0 2 * * * /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e --gpg-key-id 66B9829C backup-push /var/lib/postgresql/9.3/main > /tmp/wal-e_backup_push.log;
# Chef Name: trim wal-e backups
0 18 * * * /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e delete --confirm retain 8 > /tmp/wal-e_backup_delete.log;
```

WAL files are sent via PostgreSQL's `archive_command` parameter, which looks something like the following:

```
archive_command = /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e --gpg-key-id 66B9829C wal-push %p
```

### How do I Verify This?

You can always check the GCS storage bucket, or you can check the logs of the PostgreSQL server:

```bash
root@db1:~# tail -f /var/log/gitlab/postgresql/current
2018-11-15_12:39:13.91682         DETAIL: Archiving to "gs://gitlab-gprd-postgres-backup/pitr-wale-v1/wal_005/00000006000096F30000006A.lzo" complete at 10986.4KiB/s.
2018-11-15_12:39:13.91682         STRUCTURED: time=2018-11-15T12:39:13.916366-00 pid=41960 action=push-wal key=gs://gitlab-gprd-postgres-backup/pitr-wale-v1/wal_005/00000006000096F30000006A.lzo prefix=pitr-wale-v1/ rate=10986.4 seg=00000006000096F30000006A state=complete
2018-11-15_12:39:13.95760 wal_e.worker.upload INFO     MSG: completed archiving to a file
```

## Restoring Data

### Oh Sh*t, I Need to Get It BACK!

Before we start, take a deep breath and don't panic.

#### Production

Consider using the delayed replica to speed up PITR. The full database backup restore is also automated in a [CI pipeline](https://gitlab.com/gitlab-restore/postgres-gprd) which may be helpful depending on the type of disaster.

In order to restore, the following steps should be performed. It is assumed that you have already set up the new server and that server is configured with our current chef configuration.

1. Log in to the `gitlab-psql` user (`su - gitlab-psql`)

1. Create restore.conf file.

    ```
    cat > /var/opt/gitlab/postgresql/data/recovery.conf <<RECOVERY
    restore_command = '/usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e wal-fetch -p 4 "%f" "%p"'
    recovery_target_timeline = 'latest'
    RECOVERY
    chown gitlab-psql:gitlab-psql/var/opt/gitlab/postgresql/data/recovery.conf
    ```

1. Restore the base backup

    ```
    /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e backup-list
    PGHOST=/var/opt/gitlab/postgresql/ PATH=/opt/gitlab/embedded/bin:/opt/gitlab/embedded/sbin:$PATH /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e backup-fetch /var/opt/gitlab/postgresql/data <backup name from backup-list command>
    ```

    To restore latest backup you can use the following:

    ```
    /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e backup-list
    PGHOST=/var/opt/gitlab/postgresql/ PATH=/opt/gitlab/embedded/bin:/opt/gitlab/embedded/sbin:$PATH /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e backup-fetch /var/opt/gitlab/postgresql/data LATEST
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

        ```
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

    ```
    gpg --allow-secret-key-import --import /etc/wal-e.d/ops-contact+dbcrypt.key
    gpg --import-ownertrust /etc/wal-e.d/gpg_owner_trust
    ```

1. Enable gpg-agent in gpg.conf

    ```
    echo 'use-agent' > ~/.gnupg/gpg.conf
    ```

1. Add password and test secret keys. This should ask for a password and then create an encrypted file at `/tmp/test.gpg`.

    ```
    touch /tmp/test
    gpg --encrypt -r 66B9829C /tmp/test
    ```

1. If you have changed to the postgres user via `su`, you will need to be sure `GPG_TTY` is exported and tty device is read/write by postgres user.

    ```
    root$ chmod o+rw $(tty)
    postgres$ export GPG_TTY=$(tty)
    ```

1. Create restore.conf file.

    ```
    # precreate recovery.conf, edit the recovery target time to your desired restore time. Ensure the time is AFTER the base backup time.
    export RESTORE_PG_VER=9.5 # 9.3 in case of 14.04
    cat > /var/lib/postgresql/${RESTORE_PG_VER}/main/recovery.conf <<RECOVERY
    restore_command = '/usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e wal-fetch "%f" "%p"'
    recovery_target_time = '2017-XX-YY 06:00:00'
    RECOVERY
    chown postgres:postgres /var/lib/postgresql/${RESTORE_PG_VER}/main/recovery.conf
    ```

1. Restore the base backup

    ```
    /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e backup-list
    /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e backup-fetch /var/lib/postgresql/${RESTORE_PG_VER}/main <backup name from backup-list command>
    ```

    To restore latest backup you can use the following:

    ```
    /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e backup-list 2>/dev/null | tail -1 | cut -d ' ' -f1 | xargs -n1 /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e backup-fetch /var/lib/postgresql/${RESTORE_PG_VER}/main
    ```

1. This command will output nothing if it is successful.

1. Start PostgreSQL. This will begin the point-in-time recovery to the time specified in recovery.conf. You can watch the progress in the postgres log.

[Wal-E]: https://github.com/wal-e/wal-e
[PSQL_Archiving]: https://www.postgresql.org/docs/9.6/static/continuous-archiving.html
[PSQL_WAL]: https://www.postgresql.org/docs/current/static/wal-intro.html

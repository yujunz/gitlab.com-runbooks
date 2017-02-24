# Using Wal-E

## Wal-E Overview

[Wal-E][Wal-E] was designed by Heroku to solve their PostgreSQL
backup issues. It is a python based application that is invoked by the PostgreSQL process
via the 'archive_command' as part of PostgreSQLs 
[continuous archiving][PSQL_Archiving] setup.

It works by taking [Write-Ahead Logging][PSQL_WAL]
files, compressing them, and then archiving them off to a storage target in near realtime. 
On a nightly schedule Wal-E also pushes a full backup to the storage target, referred to
as a 'base backup'. A restore then is a combination of a 'base backup' and all of the 
WAL transaction files since the backup to recover the database to a given point in time.

## Backing Our Data Up

### Where is Our Data Going

Currently our data is being streamed to Amazon S3 into a bucket labeled `gitlab-dbprod-backups`.

### How Does it Get There?

On our production database server we have two cron jobs located in:

```
root@db1:/etc/cron.d# ls -lah backup*
-rw-r--r-- 1 root root 249 Feb 24 08:49 backup-push
-rw-r--r-- 1 root root 198 Feb 24 08:50 backup-trim
root@db1:/etc/cron.d#
```

The contents of `backup-push` are as follows:

```cron
00 02 * * * gitlab-psql PGHOST=/var/opt/gitlab/postgresql/ PATH=/opt/gitlab/embedded/bin:/opt/gitlab/embedded/sbin:$PATH /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e backup-push /var/opt/gitlab/postgresql/data > /tmp/wal-e_backup_push.log;
```

We can see here that we are starting the 'base backup' every morning at 02:00 UTC.

The contents of `backup-trim` are as follows:

```cron
00 18 * * * gitlab-psql PATH=/opt/gitlab/embedded/bin:/opt/gitlab/embedded/sbin:$PATH /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e delete --confirm retain 8 > /tmp/wal-e_backup_delete.log;
```

We can see here that we are starting the backup retention script at 18:00 UTC.
This script trims the 'base backups' and WAL segments down to just the last 8 days.

### How do I Verify This?

You can always check the S3 storage bucket, or you can check the logs of the PostgreSQL server:

```bash
root@db1:~# tail -f /var/log/gitlab/postgresql/current | grep -i wal_
2017-02-24_09:31:01.15531 db1 postgresql: wal_e.worker.upload INFO     MSG: begin archiving a file
2017-02-24_09:31:01.15573 db1 postgresql:         DETAIL: Uploading "pg_xlog/0000000200000BF800000090" to "s3://gitlab-dbprod-backups/db1/wal_005/0000000200000BF800000090.lzo".
2017-02-24_09:31:01.15588 db1 postgresql:         STRUCTURED: time=2017-02-24T09:31:01.153419-00 pid=61703 action=push-wal key=s3://gitlab-dbprod-backups/db1/wal_005/0000000200000BF800000090.lzo prefix=db1/ seg=0000000200000BF800000090 state=begin
2017-02-24_09:31:01.81012 db1 postgresql: wal_e.worker.upload INFO     MSG: completed archiving to a file
2017-02-24_09:31:01.81034 db1 postgresql:         DETAIL: Archiving to "s3://gitlab-dbprod-backups/db1/wal_005/0000000200000BF800000090.lzo" complete at 17302.3KiB/s.
2017-02-24_09:31:01.81043 db1 postgresql:         STRUCTURED: time=2017-02-24T09:31:01.806205-00 pid=61703 action=push-wal key=s3://gitlab-dbprod-backups/db1/wal_005/0000000200000BF800000090.lzo prefix=db1/ rate=17302.3 seg=0000000200000BF800000090 state=complete
^C
root@db1:~#
```

## Restoring Data

### Oh Sh*t, I Need to Get It BACK!

Before we start, take a deep breath and don't panic.

1. Stop the PostgreSQL database server:
 `root@db2:~# gitlab-ctl stop postgresql`

1. Create the `/var/opt/gitlab/postgresql/data/recovery.conf` file with the following contents:
 > restore_command = '/usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e wal-fetch "%f" "%p"'
 > recovery_target_time = '2017-02-01 02:12:00'
 > pause_at_recovery_target = 'false'
 Where the `recovery_target_time` is to your liking.

1. Start the PostgreSQL database server:
 `root@db2:~# gitlab-ctl start postgresql`

1. When the restore is finished the dabbase server will come online with the data.



[Wal-E]: https://github.com/wal-e/wal-e
[PSQL_Archiving]: https://www.postgresql.org/docs/9.6/static/continuous-archiving.html
[PSQL_WAL]: https://www.postgresql.org/docs/current/static/wal-intro.html



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

Currently our production data is being streamed to Amazon S3 into a bucket labeled `gitlab-dbprod-backups`. Our secondary databases (version, customers, sentry, etc) 
are in a bucket labeled `gitlab-secondarydb-backups`.

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

1. Stop the PostgreSQL database server: `root@db2:~# gitlab-ctl stop postgresql`

1. If you are restoring from nothing you must restore a base backup first.

  1. Get the name of the backup you need to restore to.

    ```
    root@db2:~# /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e backup-list
    wal_e.main   INFO     MSG: starting WAL-E
        DETAIL: The subcommand is "backup-list".
        STRUCTURED: time=2017-03-22T22:22:31.375375-00 pid=50745
    name	last_modified	expanded_size_bytes	wal_segment_backup_start	wal_segment_offset_backup_start	wal_segment_backup_stop	wal_segment_offset_backup_stop
    base_0000000200000C9B00000000_08600896	2017-03-08T03:44:45.000Z		0000000200000C9B00000000	08600896
    base_0000000200000CD900000018_01153720	2017-03-12T03:36:49.000Z		0000000200000CD900000018	01153720
    base_0000000200000CF000000062_00006728	2017-03-14T03:40:32.000Z		0000000200000CF000000062	00006728
    base_0000000200000D3F000000DF_05843488	2017-03-17T03:45:14.000Z		0000000200000D3F000000DF	05843488
    base_0000000200000D5C00000069_00029088	2017-03-18T03:38:03.000Z		0000000200000D5C00000069	00029088
    base_0000000200000D6D000000C5_09408544	2017-03-19T03:45:06.000Z		0000000200000D6D000000C5	09408544
    base_0000000200000D7D00000060_00000080	2017-03-20T03:47:02.000Z		0000000200000D7D00000060	00000080
    base_0000000200000DCA000000D7_09026584	2017-03-22T03:43:53.000Z		0000000200000DCA000000D7	09026584
    ```

  1. Begin a restore of the base backup.

    ```
    /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e backup-fetch /var/opt/gitlab/postgresql/data base_0000000200000DCA000000D7_09026584
    ```

1. Create the `/var/opt/gitlab/postgresql/data/recovery.conf` file with the following contents.
Please be sure that the file is owned by the postgres user (gitlab-psql in prod or postgres otherwise)
 > restore_command = '/usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e wal-fetch "%f" "%p"'
 > 
 > recovery_target_time = '2017-02-01 02:12:00'
 >  
 > pause_at_recovery_target = 'false'
 Where the `recovery_target_time` is to your liking.

1. Start the PostgreSQL database server:
 `root@db2:~# gitlab-ctl start postgresql`

1. When the restore is finished the database server will come online with the data.



[Wal-E]: https://github.com/wal-e/wal-e
[PSQL_Archiving]: https://www.postgresql.org/docs/9.6/static/continuous-archiving.html
[PSQL_WAL]: https://www.postgresql.org/docs/current/static/wal-intro.html



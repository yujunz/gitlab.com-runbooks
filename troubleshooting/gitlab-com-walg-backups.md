### How to check WAL-G backups are running

#### Base backup 

Base backup is running as a daily cron job under the Postgresql user (gitlab-psql).

Run `sudo -u gitlab-psql  ` and `crontab -l | grep backup` it should output 

```# Chef Name: full wal-g backup
0 3 * * * /opt/wal-g/bin/backup.sh > /var/log/wal-g/wal-g_backup_push.log 2>&1
```

On patroni cluster this job would take backup on only **one of the read replica**. Note that this backup job would refuse to run on master node in a patroni cluster and outputs ```it's a master``` then quit. Because we implemented wal-g to only run on read replicas to reduce master node load.

dbmon bot posts the a message to #database slack channel reporting which read replica takes the backup and the duration like below :

```Backup successfully completed on patroni-02-db-gstg. Duration: 00:47:11```

To check the backup issues, login to the reported host (in above picture the host is patroni-02-db-gstg) and check the log file `sudo cat /var/log/wal-g/wal-g_backup_push.log`

#### wal file backup

wal files are archived by the script defined in postgresql parameter `archive_command`

As specified via Chef :

```
    gitlab_rb:
      postgresql:
        archive_command:  "/opt/wal-g/bin/archive-walg.sh %p"
```

To troubleshoot wal archive issues, check log file `/var/log/wal-g/wal-g.log` and postgresql log file ` tail -f /var/log/gitlab/postgresql/postgresql | grep archive `

Normally, WAL-G will output log lines like the following in `/var/log/wal-g/wal-g.log`:

```
Path: pitr-walg-v1/
INFO: 2019/01/17 21:20:40.403573 FILE PATH: 0000003C00003544000000CF.lz4
```

If WAL-G is not working, it will probably be something related with the network or GCS. 

### I got an alert but WAL-G is working
The problem might be `mtail`.

1. Check `mtail` is working with `sudo sv status mtail`
1. If `mtail` is up, check `/var/log/mtail` for errors under `/var/log/mtail.ERROR`.
1. You might want to restart `mtail` if it's stuck with `sudo sv restart mtail`.

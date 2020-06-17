### How to check if WAL-E backups are running

> General note: the following instructions are also applicable to WAL-G (because WAL-G is compatible with WAL-E and has the same comands to create backups, `backup-push` and `wal-push`). As of June 2020, we still use WAL-E to create backups, but already switched to WAL-G to restore from backups. Once the migration to WAL-G is fully complete, we are going to update this document to mention WAL-G only.

WAL-E is installed on all machines in the Patroni cluster. However, backup creation are actually happening only from the primary (in the case of WAL-E, this is true for both "full" daily backups and archiving of the WAL stream). In order to find out which machine is the primary, go to the [relevant Grafana dashboard](https://dashboards.gitlab.net/d/000000244/postgresql-replication-overview?orgId=1)

You can check WAL-E's logs in two ways:
1. using Kibana (bear in mind that there were cases in the past when logs where not shipped; IMPORTANT: only `wal-push` logs are to be present in Kibana): <!-- Nik: TODO: adjust when backup-push logs will be moved to syslog, see https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10499 -->
  - [`log.gprd.gitlab.net`](https://log.gprd.gitlab.net)
  - index: `pubsub-system-inf-gprd`
  - document field: `json.ident` with value `wal_e*`
2. by logging directly into the VM:
  - ssh to the patroni master
  - logs are located in `/var/log/wal-e/wal-e_backup_push.log` (and are also duplicated in `/var/log/syslog`, look for `wal\_e.worker.upload`)


Example of a log entry on a master working correctly:
```
2019-06-07_16:50:42 patroni-04-db-gprd wal_e.worker.upload  INFO     MSG: begin archiving a file#012        DETAIL: Uploading "pg_xlog/000000140001003100000077" to "gs://gitlab-gprd-postgres-backup/pitr-wale-v1/wal_005/000000140001003100000077.lzo".#012        STRUCTURED: time=2019-06-07T16:50:42.145335-00 pid=35067 action=push-wal key=gs://gitlab-gprd-postgres-backup/pitr-wale-v1/wal_005/000000140001003100000077.lzo prefix=pitr-wale-v1/ seg=000000140001003100000077 state=begin
```

Example of log entries on a slave working correctly (no backups are actually happening from slaves):
```
2019-06-07_00:00:03 patroni-01-db-gprd wal_e.main    INFO     MSG: starting WAL-E#012        DETAIL: The subcommand is "backup-push".#012        STRUCTURED: time=2019-06-07T00:00:03.077171-00 pid=37922
2019-06-07_00:00:05 patroni-01-db-gprd wal_e.operator.backup  WARNING  MSG: blocking on sending WAL segments#012        DETAIL: The backup was not completed successfully, but we have to wait anyway.  See README: TODO about pg_cancel_backup#012        STRUCTURED: time=2019-06-07T00:00:05.263203-00 pid=37922
2019-06-07_00:00:05 patroni-01-db-gprd wal_e.main    ERROR    MSG: Could not stop hot backup#012        STRUCTURED: time=2019-06-07T00:00:05.296652-00 pid=37922
```

### WAL-E is not working

#### WAL-E process stuck ####

WAL-E works by uploading files to a GCS bucket every few seconds. The upload is done by a forked process which lives only a few seconds. For each successful upload there should be log entries similar to this:
```
2019-10-03_12:07:33 patroni-02-db-gprd wal_e.worker.upload  INFO     MSG: begin archiving a file#012        DETAIL: Uploading "pg_xlog/0000001D00014F69000000E7" to "gs://gitlab-gprd-postgres-backup/pitr-wale-v1/wal_005/0000001D00014F69000000E7.lzo".#012        STRUCTURED: t
ime=2019-10-03T12:07:33.719239-00 pid=20408 action=push-wal key=gs://gitlab-gprd-postgres-backup/pitr-wale-v1/wal_005/0000001D00014F69000000E7.lzo prefix=pitr-wale-v1/ seg=0000001D00014F69000000E7 state=begin
2019-10-03_12:07:34 patroni-02-db-gprd wal_e.worker.upload  INFO     MSG: completed archiving to a file#012        DETAIL: Archiving to "gs://gitlab-gprd-postgres-backup/pitr-wale-v1/wal_005/0000001D00014F69000000E7.lzo" complete at 14281KiB/s.#012        STRUCTURED: time=2
019-10-03T12:07:34.439057-00 pid=20408 action=push-wal key=gs://gitlab-gprd-postgres-backup/pitr-wale-v1/wal_005/0000001D00014F69000000E7.lzo prefix=pitr-wale-v1/ rate=14281 seg=0000001D00014F69000000E7 state=complete
```

If you're not seeing logs like this (e.g. nothing writes to the log file or there are only entries with `state=begin` but not with `state=complete`) then there's something wrong with WAL-E.

##### Check the WAL-E upload process

Run ps a few times (the upload process is short-lived so you might not catch it the first time), example output:
```
# ps aux | grep 'wal-push'
gitlab-+ 29632  0.0  0.0   4500   844 ?        S    12:16   0:00 sh -c /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e wal-push pg_xlog/0000001D00014F6B000000A2
gitlab-+ 29633 35.0  0.0 124200 41488 ?        D    12:16   0:00 /opt/wal-e/bin/python /opt/wal-e/bin/wal-e wal-push pg_xlog/0000001D00014F6B000000A2
root     29638  0.0  0.0  12940   920 pts/0    S+   12:16   0:00 grep wal-push
```

If the timestamp on the wall-e process is relatively long time in the past (e.g. 15 mins, 1h) then that's a hint that it's stuck at uploading files.

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

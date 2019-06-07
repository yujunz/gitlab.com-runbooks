### How to check if WAL-E backups are running

WAL-E is running on all machines in the patroni cluster. However, backups are actually happening only from the master. In order to find out which machine is the master, go to the [relevant Grafana dashboard](https://dashboards.gitlab.net/d/000000244/postgresql-replication-overview?orgId=1)

you can check wale logs in two ways:
1. using Kibana (bear in mind that there were cases in the past when logs where not shipped):
  - [`log.gitlab.net`](log.gitlab.net)
  - index: `pubsub-postgres-inf-gprd`
  - document field: `json.tag` with value `db.wale`
2. by logging directly into the VM:
  - ssh to the patroni master
  - logs are located in `/var/log/gitlab/postgresql/`, the latest log file is most likely called: `wale.log.1` (assumming rotation is happening correctly)


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

WAL-E works by uploading files to a GCS bucket every few seconds. For each upload there should be a log entry.

at the moment of writing, the output from ps that contains the wall-e upload process looks similar to:
```
(...) /opt/wal-e/bin/python /opt/wal-e/bin/wal-e wal-push (...)
```

If you don't see any log entries and there is a wal-e upload process hanging for a long time, consider checking the state of the process with `strace`. If it's not doing anything, consider killing the wal-e upload process. BE EXTREMELY CAREFUL! After killing the process the backups should resume immediately.

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

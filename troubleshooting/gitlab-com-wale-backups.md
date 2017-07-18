### How to check WAL-E backups are running

1. Log into `db1.cluster.gitlab.com`
1. Run `sudo tail -f /var/log/gitlab/postgresql/current | grep --line-buffered wal_`.

Normally, WAL-E will output log lines like the following:
```
2017-07-18_09:35:14.61149 db1 postgresql: wal_e.worker.upload INFO     MSG: completed archiving to a file
2017-07-18_09:35:14.61171 db1 postgresql:         DETAIL: Archiving to "s3://foo/db1/wal_005/0000000200001AAB00000036.lzo" complete at 11884.8KiB/s.
2017-07-18_09:35:14.61179 db1 postgresql:         STRUCTURED: time=2017-07-18T09:35:14.610853-00 pid=15626 action=push-wal key=s3://foo/db1/wal_005/0000000200001AAB00000036.lzo prefix=db1/ rate=11884.8 seg=0000000200001AAB00000036 state=complete
```

If WAL-E is not working, it will probably be something related with the network or S3.

PostgreSQL is configured to archive to WAL-E upon some conditions, as specified via Chef:
```
    gitlab_rb:
      postgresql:
        archive_command:              /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e wal-push %p
```

### I got an alert but WAL-E is working
The problem might be `mtail`.

1. Check `mtail` is working with `sudo sv status mtail`
1. If `mtail` is up, check `/var/log/mtail` for errors under `/var/log/mtail.ERROR`.
1. You might want to restart `mtail` if it's stuck with `sudo sv restart mtail`.

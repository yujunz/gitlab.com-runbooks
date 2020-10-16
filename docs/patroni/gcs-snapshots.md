# Patroni GCS Snapshots

We take GCS snapshots of the data disk of a Patroni replica periodically
(period specified by Chef's `node['gitlab-patroni']['snapshot']['cron']['hour']`).
Only one specific replica is used for the purpose of a snapshot, and this replica
does not receive any client connections nor participate in a leader election when
a failover occurs.

The replica is assigned a special Chef role `<env>-base-db-patroni-backup-replica`
in Terraform, here is an [example][tf-replica-example] from the production environment.

A cron job runs a Bash script (by default it is found in `/usr/local/bin/gcs-snapshot.sh`). The script run
the snapshot operation (i.e. `gcloud compute snapshot ...`) sandwiched between a `pg_start_backup` and `pg_stop_backup`
PostgreSQL calls, to ensure the integrity of the data. After a successful snapshot run, the script hits the local
Prometheus Pushgateway with the current timestamp for observability.

## Troubleshooting

### "Last Patroni GCS snapshot did not run successfully" alert

If the snapshot operation failed for any reason, the script won't hit Prometheus Pushgateway, which will eventually
trigger an alert.

Check the logs for any clues, log file names have the following pattern `/var/log/gitlab/postgresql/gcs-snapshot-*`, check
the last ones and see if an error is logged.

Try running the script manually like this and see if it exits successfully:

```
$ sudo su - gitlab-psql
$ /usr/local/bin/gcs-snapshot.sh
```

[tf-replica-example]: https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/blob/235d69658055dd8174d774340d8a67734d997129/environments/gprd/main.tf#L825

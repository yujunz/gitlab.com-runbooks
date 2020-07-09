# Postgres Replicas

<!-- vim-markdown-toc GitLab -->

* [Overview](#overview)
* [Setup](#setup)
  * [Setup Replication](#setup-replication)
    * [Pre-requisites](#pre-requisites)
      * [recovery.conf for archive replica](#recovery.conf-for-archive-replica)
      * [recovery.conf for delayed replica](#recovery.conf-for-delayed-replica)
    * [Restoring with WAL-G](#restoring-with-wal-g)
    * [Restoring with a disk-snapshot](#restoring-with-a-disk-snapshot)
* [Check Replication Lag](#check-replication-lag)
* [Pause Replay on Delayed Replica](#pause-replay-on-delayed-replica)

<!-- vim-markdown-toc -->

## Overview

Besides our Patroni-managed databases we also have 2 single Postgresql instances
for disaster recovery and wal archive testing purposes:

* gprd:
  * postgres-dr-archive-01-db-gprd.c.gitlab-production.internal
  * postgres-dr-delayed-01-db-gprd.c.gitlab-production.internal
* gstg:
  * postgres-dr-archive-01-db-gstg.c.gitlab-staging-1.internal
  * postgres-dr-delayed-01-db-gstg.c.gitlab-staging-1.internal

Archive and delayed replica both are replaying WAL archive files from GCS via
wal-g which are send to GCS by the Patroni primary (with a [retention
policy](https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/google/database-backup-bucket/-/merge_requests/10)
sending them to nearline storage after 2 weeks and deletion after 120 days).
The delayed replica though is replaying them with an 8 hour delay, so we are
able to retrieve deleted objects from there within 8h after deletion if needed.

The archive replica is also used for long-running queries for business
intelligence purposes, which would be problematic to run on the patroni cluster.

The "dr" in the name often was leading to confusion with the also existing DR
environment (which isn't existing anymore and which those DBs never belonged
to).

## Setup

Both instances are setup using terraform and Chef:

* [gprd-base-db-postgres-archive role](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/-/blob/master/roles/gprd-base-db-postgres-archive.json)
* [gprd-base-db-postgres-delayed role](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/-/blob/master/roles/gprd-base-db-postgres-delayed.json)

They use the postgresql version coming with omnibus.

### Setup Replication

While most configuration is already done by Chef, the initial replication needs
to be setup manually. This needs to be done when re-creating the node or if
replication is broken for some reason (e.g. diverged timeline WAL segments in
GCS after a primary failover or for a major postgres version upgrade).

There are 2 ways to (re-)start replication:

* Using wal-g to fetch a base-backup from GCS (easy and works in all cases, but slow)
* Using a disk snapshot from the dr replica before replication broke (faster,
  but a bit more involved and mostly applicable for diverged timelines after a
  failover). You also could take a snapshot from a patroni node, but then you
  need to move PGDATA from `.../data11` to `.../data` manually.

#### Pre-requisites

Make sure the postgresql version on this node is compatible with the patroni
one. Else you need to upgrade the gitlab-ee package to a version that brings a
matching embedded postgresql version.

```
/opt/gitlab/embedded/bin/postgres --version
```

Make sure wal-g is working and able to find the latest base backups:

```
cd /tmp/; sudo -u gitlab-psql /usr/bin/envdir /etc/wal-g.d/env /opt/wal-g/bin/wal-g backup-list
name                                   last_modified        wal_segment_backup_start
base_000000020000492A000000E2_00036848 2020-06-04T13:49:56Z 000000020000492A000000E2
base_000000020000493E0000006D_00000040 2020-06-05T07:42:27Z 000000020000493E0000006D
...
```

The `/var/opt/gitlab/postgresql/data/recovery.conf` file is not managed by
configuration management nor backed up by WAL-G and needs to be setup manually.

##### recovery.conf for archive replica

```
standby_mode = 'on'
restore_command = '/usr/bin/envdir /etc/wal-g.d/env /opt/wal-g/bin/wal-g wal-fetch "%f" "%p"'
recovery_target_timeline = 'latest'
```

##### recovery.conf for delayed replica

```
standby_mode = 'on'
restore_command = '/usr/bin/envdir /etc/wal-g.d/env /opt/wal-g/bin/wal-g wal-fetch "%f" "%p"'
recovery_target_timeline = 'latest'
recovery_min_apply_delay = '8h'
```

#### Restoring with WAL-G

We will delete the content of the existing PGDATA dir and re-fill it using
wal-g. Retrieving the base-backup will take several hours (1.5 - 2 TiB/h -> ~3.5 - 4.5 hours for a 7TiB database) and
then fetching and replaying the necessary WAL files since the base-backup also can
take a few hours, depending on how much time passed since the last base-backup.

* make a backup copy of `recovery.conf`:
  * `cp -a /var/opt/gitlab/postgresql/data/recovery.conf $HOME/`
* `system-ctl stop chef-client`
* `gitlab-ctl stop postgresql`
* Clean up the current PGDATA: `rm -rf /var/opt/gitlab/postgresql/data/*`
* Run backup-fetch __in a tmux__ as it will take hours:
  * `cd /tmp/; sudo -u gitlab-psql /usr/bin/envdir /etc/wal-g.d/env /opt/wal-g/bin/wal-g backup-fetch /var/opt/gitlab/postgresql/data/ LATEST`
* copy back the recovery.conf file, make sure it is looking like [above](#pre-requisites)
  * `cp -a $HOME/recovery.conf /var/opt/gitlab/postgresql/data/`
* run `gitlab-ctl reconfigure` to create a proper postgresql.conf, check it
* make sure postgresql is started: `gitlab-ctl start postgresql`
* check logs in `/var/opt/gitlab/postgresql/current` - postgres should be in
  startup first and then start replaying WAL files all the time
* `system-ctl start chef-client`

#### Restoring with a disk-snapshot

This is faster than downloading a base-backup first (at least for gprd - for
gstg downloading a base-backup takes around half an hour). We will create a new
disk from the latest data disk snapshot of the postgres dr instance and mount it
in place of the existing data disk and then start WAL fetching.

* make a screenshot of the order of attached disks of the instance in google
  cloud console
* get the config of the current data disk:

```
env="gprd"
project="gitlab-production"
instance="postgres-dr-archive-01-db-gprd"  # adjust for the wanted instance
disk_name="${instance}-data"

gcloud compute disks list --filter="name: $disk_name" --format=json

zone=<zone-from-above>
size=<size in Gb from above>
labels="key1=value1,key2=value2,..."  # from labels above
```

* find the last data disk snapshot:

```
gcloud compute snapshots list --filter="sourceDisk~$disk_name" --sort-by=creationTimestamp --format=json

snapshot_name=<name of last snapshot from above>
```

* adjust the `/etc/fstab` entry for the data disk to also make it work for the
  new disk:
  * replace `UUID=...` for the mount point `/var/opt/gitlab` with `/dev/disk/by-id/google-$disk_name` (and make sure this device really exists)
* exchange the disk with a new one created from the snapshot:

```
# stop the instance
gcloud --project $project --zone $zone compute instances stop $instance

# detach the disk
gcloud --project $project --zone $zone beta compute instances detach-disk $instance --disk $disk_name

# delete the disk
gcloud --project $project --zone $zone beta compute disks delete $disk_name

# create new disk from snapshot (takes 20m or more)
gcloud --project $project --zone $zone beta compute disks create $disk_name --type pd-ssd --source-snapshot $snapshot_name --labels="$labels"

# attach disk
gcloud --project $project --zone $zone compute instances attach-disk $instance --disk $disk_name --size ${size}GB --device-name data

# start instance
gcloud --project $project --zone $zone compute instances start $instance
```

It could be that the data disk isn't mounted correctly, because Linux tries to
mount by the enumerated order of the disks. Try to reshuffle the
order of disks on the instance in google cloud console by detaching and
attaching them accordingly until they match the original order that you saved in
the screenshot at the beginning.

If everything worked out, postgres should be recovering now and replication lag
catching up slowly.

* Check there is no terraform plan diff for the archival replicas. Run the
  following for the matching environment:

 ```
 tf plan -out plan -target module.postgres-dr-archive -target module.postgres-dr-delayed
 ```

 If there is a plan diff for mutable things like labels, apply it. If there is
 a plan diff for more severe things like disk name, you might have made a
 mistake and will have to repeat this whole procedure.

## Check Replication Lag

[Thanos](https://thanos-query.ops.gitlab.net/graph?g0.range_input=1h&g0.max_source_resolution=0s&g0.expr=pg_replication_lag%7Benv%3D%22gprd%22%2C%20fqdn%3D~%22postgres-dr.*%22%7D&g0.tab=0)

## Pause Replay on Delayed Replica

If we want to restore content that was changed/deleted less than 8h before on
our Patroni cluster, we can do it on the delayed replica, because it is
replaying the WAL files with an 8h delay. To prevent reaching the 8h limit, we
can temporarily pause the replay:

* eventually silence replication lag alerts first
* ssh to the delayed replica
* `systemctl stop chef-client`
* `gitlab-psql -c 'SELECT pg_xlog_replay_pause();'`
* extract the data you need...
* `gitlab-psql -c 'SELECT pg_xlog_replay_resume();'`
* `systemctl start chef-client`

Also see the [deleted-project-restore runbook](../uncategorized/deleted-project-restore.md).

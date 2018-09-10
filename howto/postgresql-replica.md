# Adding a PostgreSQL replica

From time to time, it may be necessary to add a new PostgreSQL replica
to our cluster. This is a fairly straightforward operation, but there are some unintuitive steps.

1. Build the server(s) via terraform. This is as easy as bumping the number in the
   postgres module. Please see [this merge request](https://gitlab.com/gitlab-com/gitlab-com-infrastructure/merge_requests/203)
1. Add servers to chef with the proper roles. They should be automatically bootstrapped 
   via terraform.
    * role[gitlab-base-db-postgres]
    * role[gitlab-base-db-postgres-replication]
1. Run `chef-client` to configure. This will create the proper LVM volumes and install and configure PostgreSQL.
1. Ensure there are no users with the UIDs between `1101-1106`. `gitlab-ctl reconfigure` will try to create users with those UIDs and fail if they already exist.
1. Disable repmgr, pgbouncer, and consul (omnibus, not normal) in `gitlab.rb`. 
1. Due to a as of yet resolved bug, ensure correct permissions on `/dev/null` (they should be 666).
1. Run `gitlab-ctl reconfigure`.
1. Enable repmgr, pgbouncer, and consul in `gitlab.rb` and run reconfigure.
    * You will need to run the reconfigure twice.
1. Update hosts file to point master hostname to internal IP address.
1. Run gitlab command to [bootstrap as secondary db node](https://docs.gitlab.com/ee/administration/high_availability/database.html#secondary-nodes).
    * This will take a long time.
    * This may timeout at the very end. That is OK, just run the register command manually `gitlab-ctl repmgr standby register`.
1. Check if the node is added via `gitlab-ctl repmgr cluster show`.
    * The output should include the new server, something like
    ```
    standby | postgres-04.db.prd.gitlab.com | db3.cluster.gitlab.com | host=postgres-04.db.prd.gitlab.com port=5432 user=gitlab_repmgr dbname=gitlab_repmgr
    ```

This will produce a production ready replica of the production database.

# Using pg_basebackup to resync a replica

If a replica gets out of sync or fails for some reason, you have several options to recover:

1. Run pg_basebackup from the secondary
2. Use [Wal-E](using-wale-gpg.md) to restore a backup and catch up from
   there
3. Take a disk snapshot of the primary and clone it on the secondary. Be
   sure to [drop replication slots on the secondary after it comes up](postgresql-switchover.md#dropping-replication-slots).

## Running pg_basebackup

All commands are supposed to be run on the replica in question if not
stated otherwise.

`$upstream` is the hostname of the upstream database box we want to use
to resync. This is not necessarily the primary as we can (and should!)
use another secondary for this purpose.

1. Stop PostgreSQL: `gitlab-ctl stop postgresql`
1. Backup `recovery.conf` for later reference: `cp /var/lib/gitlab/postgreql/data/recovery.conf /var/lib/gitlab/postgreql/recovery.conf.$(date +%F)`
1. Remove old data directory `mv /var/lib/gitlab/postgreql/data{,.bak}`
1. Check `/var/lib/gitlab/postgresql/repmgr.conf` to compile slot name: `repmgr_slot_$node` (`$node` is from repmgr.conf)
1. Connect to `$upstream` and create physical replication slot on a
   `gitlab-psql` session: `select pg_create_physical_replication_slot($slot)`
1. Start `pg_basebackup` process (preferably in tmux session as this
   takes a while): `sudo -u gitlab-psql PGSSLMODE=disable /opt/gitlab/embedded/bin/pg_basebackup -D /var/opt/gitlab/postgresql/data --slot=$slot -c fast -X stream -P --host=$upstream -p 5432 --username=gitlab_repmgr -R`
1. Once finished, review `recovery.conf` and compare with backup in `/var/lib/gitlab/postgreql/recovery.conf.$(date +%F)`. Check upstream is `$upstream`.
1. Start PostgreSQL: `gitlab-ctl start postgresql`
1. Let the new replica catch up and become in-sync with `$upstream`.
1. If `$upstream` was a secondary, reconfigure to use the primary and
   also drop the replication slot created in (5) by connecting to `$upstream` and perform a `select pg_drop_replication_slot($slot)` there
1. Make sure to clean up and remove the old data directory in `/var/lib/gitlab/postgreql/data.bak`

After having started PostgreSQL again, there are the following phases:

1. Crash recovery (during this time, the secondary is not accessible: FATAL: the database system is starting up)
1. Catchup with upstream (secondary is accessible but lags behind)

Useful things to look at:
1. `/var/log/gitlab/postgresql/current`
1. `select * from pg_stat_replication` on `$upstream`

Here's an example of a `recovery.conf` that has both streaming
replication and archive recovery enabled (note `$upstream, $fqdn, $slot`
need to be replaced):

```
standby_mode = 'on'
primary_conninfo = 'user=gitlab_repmgr password=REDACTED host='$upstream' port=5432 fallback_application_name=repmgr sslmode=prefer sslcompression=0 application_name='$fqdn''
recovery_target_timeline = 'latest'
primary_slot_name = $slot

restore_command = '/usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e wal-fetch -p 32 "%f" "%p"'
```

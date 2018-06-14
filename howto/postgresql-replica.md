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
2. Use [Wal-E](using-wale-gpg.md)
3. Take a disk snapshot of the primary and clone it on the secondary. Be
   sure to [drop replication slots on the secondary after it comes up](postgresql-switchover.md#dropping-replication-slots).

## Running pg_basebackup

You'll need:

1. Name of a replication slot on the primary (run `SELECT * FROM pg_replication_slots` on the primary)
2. Username that can replicate data (e.g. `gitlab_repmgr`)

Example:

```sh
PGSSLMODE=disable sudo -u gitlab-psql /opt/gitlab/embedded/bin/pg_basebackup -D /var/opt/gitlab/postgresql/data --slot=repmgr_slot_1631008568 -X stream -P --host=postgres-01-db-gprd.c.gitlab-production.internal -p 5432 --username=gitlab_repmgr
```

* The `PGSSLMODE=disable` environment variable is critical for speeding up the replication
* The `--slot` parameter ensures that the primary doesn't remove necessary WAL data
* The `-X stream` parameter streams the WAL segments simultaneously

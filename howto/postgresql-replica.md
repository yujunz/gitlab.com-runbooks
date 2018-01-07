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

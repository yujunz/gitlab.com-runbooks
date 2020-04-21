# Rotating Rails' PostgreSQL password

Follow the following steps in order to rotate the password of the PostgreSQL
user used by the Rails application.

The process involves creating temporary credentials to be used by the application
while we rotate the old password, in order to avoid running into unauthenticated
connection errors.

Create a [C1 change request](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/new?issuable_template=change_c1),
add the steps below to the request, changing the following:
* `[old-username]` to the current username used by the Rails application, usually it is `gitlab`
* `[temp-username]` to anything reasonable, e.g. `gitlab-app`
* `<env>` to the target environment identifier, e.g. `gstg`, `gprd`, `dr`, ...

There are inline comments, to explain some of the steps, pay attention to them.

```
1. [ ] On a database node, run `sudo -u gitlab-psql /usr/lib/postgresql/9.6/bin/pg_dumpall -h localhost -p 5432 -U gitlab-superuser --roles-only | grep 'ROLE [old-username]\b'`
    <!--
    If the old username contains a dash, then you need to wrap the username in double-quotes and drop the `\b` e.g. `grep ROLE "gitlab-app"`

    An output will be like:
    CREATE ROLE gitlab;
    ALTER ROLE gitlab WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS CONNECTION LIMIT 270 ENCRYPTED PASSWORD  'md5foobarbaz';
    ALTER ROLE gitlab SET statement_timeout TO '10s';
    -->
1. [ ] Copy the output, replace all occurrence of `[old-username]` with `"[temp-username]"`
1. [ ] In the output, the `ALTER ROLE ... WITH ...` line, replace `PASSWORD` with `ENCRYPTED PASSWORD` and the password after `PASSWORD` with a secure password. This will be `[temp-username]`'s password.
1. [ ] On the primary DB, in a psql console, run updated output
1. [ ] On the primary DB, in a psql console, run `GRANT [old-username] to "[temp-username]"`
1. [ ] In `gitlab-omnibus-secrets` and `gitlab-omnibus-secrets-geo` GKMS vaults, under `omnibus-gitlab.gitlab_rb.gitlab-rails`:
    1. [ ] Update `db_password` to `[temp-username]`'s password
    1. [ ] Update `db_username` to `[temp-username]`
    <!--
    Ideally, `db_username` is updated in a Chef role, but since there would a delay between applying the role
    and updating the vault, there's a chance of clients getting half of the change (i.e. `[old-username]` with
    `[temp-username]`'s password or `[temp-username]` with `[old-username]`'s password).

    Adding both db_username and db_password to the vault is important to have the new credentials updated correctly.
    -->
1. [ ] Update `omnibus-gitlab.gitlab_rb.gitlab-rails.db_username` in `<env>-base` Chef role to `[temp-username]`
    <!--
    Example: https://ops.gitlab.net/gitlab-cookbooks/chef-repo/-/merge_requests/3157/diffs
    -->
1. [ ] Converge Chef on one client node and check for errors
    1. [ ] If the single node fails to connect to the database, revert the change in GKMS as quickly as possible. Otherwise the entire fleet might pick up wrong credentials.
1. [ ] Converge Chef on the client nodes or wait for 30 minutes
1. [ ] Follow these [instructions](https://gitlab.com/gitlab-com/runbooks/-/blob/e59f5321ae6d5cfeb5119d5aeafe091486e333a9/docs/uncategorized/shared-configurations.md#executing-a-kubernetes-pipeline)
    to reflect the new changes in K8s.
1. [ ] Make sure no client is using or trying to use `[old-username]` by running all of the following:
    1. [ ] `knife ssh 'roles:<env>-base -roles:<env>-base-bastion' 'sudo test -f /var/opt/gitlab/gitlab-rails/etc/database.yml && sudo grep username /var/opt/gitlab/gitlab-rails/etc/database.yml | grep -v [temp-username]'`
        * Should be no output or output from hosts that has `reconfigure` disabled, the latter don't connect to the database anyway (e.g. redis)
    1. [ ] `knife ssh roles:<env>-base-db-patroni "sudo gitlab-psql -c \"SELECT COUNT(*) FROM pg_stat_activity WHERE usename='[old-username]'\""`
        * All counts should be zero
    1. [ ] `knife ssh 'roles:<env>-base-db-patroni roles:<env>-base-db-pgbouncer-pool' 'sudo tail -f /var/log/gitlab/pgbouncer/pgbouncer.log' | grep "password authentication failed"`
        * No recent entries should exist
1. [ ] On the primary DB, in a psql console, change the password for the old username by running `ALTER ROLE [old-username] ENCRYPTED PASSWORD '[new-password]'`
1. [ ] Update the password in 1Password or create a new entry for it. Entry name should be `<env> postgres gitlab user`
1. [ ] In `gitlab-omnibus-secrets` and `gitlab-omnibus-secrets-geo` GKMS vaults, under `omnibus-gitlab.gitlab_rb.gitlab-rails`:
    1. [ ] Update `db_password` to `[new-password]`
    1. [ ] Update `db_username` to `[old-username]`
1. [ ] Update `omnibus-gitlab.gitlab_rb.gitlab-rails.db_username` in `<env>-base` Chef role to `[old-username]`
    <!--
    Example: https://ops.gitlab.net/gitlab-cookbooks/chef-repo/-/merge_requests/3179/diffs
    -->
1. [ ] Converge Chef on one client node and check for errors
    1. [ ] If the single node fails to connect to the database, revert the change in GKMS as quickly as possible. Otherwise the entire fleet might pick up wrong credentials.
1. [ ] Converge Chef on the client nodes or wait for 30 minutes
1. [ ] Follow these [instructions](https://gitlab.com/gitlab-com/runbooks/-/blob/e59f5321ae6d5cfeb5119d5aeafe091486e333a9/docs/uncategorized/shared-configurations.md#executing-a-kubernetes-pipeline)
    to reflect the new changes in K8s.
1. [ ] Make sure no client is using or trying to use `[temp-username]` by running all of the following:
    1. [ ] `knife ssh 'roles:<env>-base -roles:<env>-base-bastion' 'sudo test -f /var/opt/gitlab/gitlab-rails/etc/database.yml && sudo grep username /var/opt/gitlab/gitlab-rails/etc/database.yml | grep [temp-username]'`
        * Should be no output or output from hosts that has `reconfigure` disabled, the latter don't connect to the database anyway (e.g. redis)
    1. [ ] `knife ssh roles:<env>-base-db-patroni "sudo gitlab-psql -c \"SELECT COUNT(*) FROM pg_stat_activity WHERE usename='[temp-username]'\""`
        * All counts should be zero
    1. [ ] `knife ssh 'roles:<env>-base-db-patroni roles:<env>-base-db-pgbouncer-pool' 'sudo tail -f /var/log/gitlab/pgbouncer/pgbouncer.log' | grep "password authentication failed"`
        * No recent entries should exist
    1. [ ] Check Sentry for any errors related to failed DB login attempts
1. [ ] On the primary DB, in a psql console, drop `[temp-username]` by running `DROP ROLE "[temp-username]"`
1. [ ] In `gitlab-omnibus-secrets` and `gitlab-omnibus-secrets-geo` GKMS vaults, remove `omnibus-gitlab.gitlab_rb.gitlab-rails.db_username` to avoid confusion
```

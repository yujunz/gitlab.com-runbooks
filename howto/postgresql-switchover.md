> To do rolling reconfigurations of Postgres including *minor*
> database upgrades follow this procedure:

## Communications

We do *not* tweet this as no user-visible downtime is expected. Users
who were making requests when the failover occurred may get errors but
on reloading it should work after up to 30s of rails retrying.

In advance of doing this verify there is no deploy in progress or
planned. Deploys will fail up until the last step when chef roles for
the deploy node and rails-db console are updated.

It *should* be safe to do this while background migrations are
running. The final failover could cause some database errors but they
should be written to retry as necessary.

One hour before doing this, and then again shortly before starting
announce it on `#production` and `#database` slack channel. There may
be alerts caused by it and the oncall *must* be aware of the work or
they could take dangerous actions such as restarting the failed
database in read-write mode.

## Create silences in alerts.gitlab.com

1. to be filled in based on experience...

## Stop chef on all database hosts
```
tail -f /var/log/sylog &
service chef-client stop
```

## Push the chef role changes from development machine
```
cd chef-repo
git push 
knife role from file roles/ENVIRONMENT-base-db-postgres.json
```

## Update each replica, restarting the database

Run these commands on each **REPLICA** database:
```
tail -f /var/log/gitlab/postgresql/current &
gitlab-ctl stop postgresql
chef-client
gitlab-ctl reconfigure
gitlab-ctl start postgresql
```

## Fail the primary
```
tail -f /var/log/gitlab/postgresql/current &
tail -f /var/log/gitlab/repmgrd/current &
gitlab-ctl stop postgres
```

Wait 60 seconds and verify that a failover was successful by running on a replica
```
gitlab-ctl repmgr cluster show
```

Continue on the primary:
```
chef-client
gitlab-ctl reconfigure
gitlab-ctl repmgr standby follow <name of new primary>
gitlab-ctl restart repmgrd
```
You may also need to drop the leftover slot using `pg_drop_replication_slot(...)` on the former primary after demoting it to a replica. Check by issuing `SELECT * FROM pg_replication_slots`. Normally there should be no replication slots on any database other than the current primary for our configuration.

## Update the hard coded primary in various chef roles

In `ENVIRONMENT-base-deploy-node.json` ensure this still points to a replica:
```
{
  "default_attributes": {
    "gitlab_users": {
      "dbconsole_db_host": "10.129.1.102",
```

And also in `ENVIRONMENT-base-deploy-node.json` ensure this points to the new primary:
```
  "override_attributes": {
    "omnibus-gitlab": {
      "gitlab_rb": {
        "gitlab-rails": {
          "db_host": "10.129.1.101",
```

## Communication

Announce the update is finished on `#production` and `#database` slack channels.


## Remove silences

* Visit alerts.gitlab.com and verify that there are no alerts firing. 
* Remove all silences created for the maintenance. 


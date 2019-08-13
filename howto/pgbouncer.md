# PgBouncer

PgBouncer is a connection pooler for PostgreSQL, allowing many frontend
connections to re-use existing PostgreSQL backend connections. For example, you
can map 1024 PgBouncer connections to 100 PostgreSQL connections.

For more information refer to [PgBouncer's
website](http://pgbouncer.github.io/).

## Pooling Mode

PgBouncer is configured to use transaction pooling. This means that every
transaction could potentially use a different PostgreSQL backend. The benefit is
that we need very little PostgreSQL connections, the downside is that temporary
state is not carried over between transactions. For example, running `SET
statement_timeout = 0` will not work reliably.

## PgBouncer Hosts

Pgbouncer is configured via omnibus via these [config options](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template#L1587).

The PgBouncer configuration files are located in `/var/opt/gitlab/pgbouncer`,
and it can include the `database.ini` file from consul, which can be found
here: `/var/opt/gitlab/consul/databases.ini`

The port PgBouncer listens on is 6432.

## PgBouncer Commands

PgBouncer is controlled using gitlab-ctl. The following commands are
available:

* `sudo gitlab-ctl restart pgbouncer`
* `sudo gitlab-ctl start pgbouncer`
* `sudo gitlab-ctl stop pgbouncer`
* `sudo gitlab-ctl reload pgbouncer`

Note that restarting PgBouncer will terminate existing connections immediately,
possibly leading to application errors.

It is also possible to connect directly to PgBouncer:

* `sudo gitlab-ctl pgb-console`

This will prompt for the pgbouncer password (can be found in *1password*)

You can also control PgBouncer when connected to it using its own set of
commands. See <http://pgbouncer.github.io/usage.html#admin-console> for more
information.

## Applying Changes

Almost all settings of PgBouncer can be managed by editing `/etc/gitlab/gitlab.rb` and running `gitlab-ctl reconfigure`.

Most settings only require a reload of pgbouncer, which should be handled by `gitlab-ctl reconfigure` and will not cause an interruption of service.

To manually reload, run `sudo gitlab-ctl reload pgbouncer`

To manually restart, run `sudo gitlab-ctl restart pgbouncer`. **Note:** This will cause an interruption to existing connections.

## Statistics

PgBouncer has its own internal set of statistics. To view these, log in to the
PgBouncer database:

    sudo gitlab-psql -h localhost -p 6432 -U pgbouncer -d pgbouncer

or

    sudo gitlab-ctl pgb-console

This will ask for a password, which you currently can find in *1password*.
Once connected you can run various commands to
get statistics, see <https://pgbouncer.github.io/usage.html#admin-console> for
more information.

## Troubleshooting

### Primary database connections are not working.

Verify that the configuration exists in the `databases.ini`

    sudo cat /var/opt/gitlab/consul/databases.ini

If there is a configuration there for the `host=db.gitlab.com` section, log into
pgbouncer itself. Verify that the configuration has been loaded (from within pgbouncer's console):

    show databases;

the entry should look something like this:

```
pgbouncer=# show databases;
            name             |          host          | port |          database           | force_user | pool_size | reserve_pool | pool_mode | max_connections | current_connections
-----------------------------+------------------------+------+-----------------------------+------------+-----------+--------------+-----------+-----------------+---------------------
 gitlabhq_production         | db.gitlab.com          | 5432 | gitlabhq_production         |            |       100 |            5 |           |               0 |                   0
 gitlabhq_production_sidekiq | db.gitlab.com          | 5432 | gitlabhq_production_sidekiq |            |       150 |            5 |           |               0 |                   0
 pgbouncer                   |                        | 6432 | pgbouncer                   | pgbouncer  |         2 |            0 | statement |               0 |                   0
```

Where the `host` field has the same value as the `databases.ini`.

If the `databases.ini` file does NOT have a valid hostname, verify that the postgresql
**service** in consul has one (and only one) host in an `up` state.

If this is the case, verify that the consul service received the last configuration change.
To do this, check the log file: `/var/log/gitlab/consul/failover_pgbouncer.log`.

If this contains a line such as this:

```
I, [2017-10-31T15:54:14.777364 #43594]  INFO -- : Running: gitlab-ctl pgb-notify --newhost db.gitlab.com --user pgbouncer --hostuser gitlab-consul
```

the notification should have been sent to the `databases.ini` file. It is possible to
re-run the command manually from the log message:

    gitlab-ctl pgb-notify --newhost db.gitlab.com --user pgbouncer --hostuser gitlab-consul

Restarting the consul service will also trigger a reconfiguration:

    gitlab-ctl restart consul

after which you should have entries in the `databases.ini`.

To propagate these changes to pgbouncer (if they have not already been refreshed via the
`gitlab-ctl pgb-notify`, the pgbouncer can re-read its configuration in two ways:

* restart pgbouncer (`gitlab-ctl restart pgbouncer`)
* running `RELOAD;` from the pgbouncer console.

### Applications can not log into pgbouncer.

Pgbouncer does not know what users exist on the database. It accepts a new connection
and executes the query configured under `auth_query` in the `pgbouncer.ini`. By default
this is: `SELECT username, password FROM public.pg_shadow_lookup($1)` for which it will
compare the credentials it received from the lookup with those it received from the
application.

If an application can not log into the db via pgbouncer, there are two places to check:

1. pgbouncer logs: `/var/log/gitlab/pgbouncer/current` to find more information
1. postgres logs: `/var/log/gitlab/postgresql/current` on the database server. If the
user pgbouncer uses to perform this `auth_query` (by default `pgbouncer`), does not
have permissions, you will see errors here.

### I think we need more connections, how can I check this?

Log in to the PgBouncer database, then run `show lists`. If `free_servers` is 0
this means you need more backend connections. If `free_clients` is 0 this means
you need more frontend connections. Both can be changed by reloading PgBouncer.

## Healthcheck/pgbouncer-leader-check

In gprd and gstg, clients access pgbouncer via an internal load balancer (ILB)
named ENV-pgbouncer-regional.

This ILB uses an HTTP healthcheck to determine which of the 3 pgbouncer nodes
are alive and ready to serve traffic.  This healthcheck is serviced on the
pgbouncer nodes with a simple python http server on port 8010.

Because we want to run with active and standby pgbouncers (to keep connection
counts to a reasonable number normally, but still have failover capability),
this is implemented with a systemd service called pgbouncer-leader-check.  This
runs `consul lock`, which uses consul and a `-n` parameter to ensure only `n`
instances of something are running across a fleet at a time.  In gprd, with 3
pgbouncer nodes and -n=2, consul lock ensures at most 2 nodes have a succeeding
healthcheck at any given point in time.  If an active node fails hard, its
`consul lock` will die, freeing a slot in the lock, the `consul lock` on the
warm spare will start the healthcheck process, and the ILB will re-route
connections.

### Normal configuration

* pgbouncer-leader-check is running on all pgbouncer nodes
* `consul lock` is running on all pgbouncer nodes
* The simple python http server is running on only `n` nodes
   * gprd => 2, gstg => 1
* The ILB will have `n` nodes active, and `3-n` nodes as warm spares.

### Gotchas

The pgbouncer-leader-check service (or rather, `consul lock`) has been known
to fail if consul isn't working correctly (e.g. if all consul nodes are
restarted at once).  If this happens, the service fails repeatedly and quickly
and systemd will shut it down.  If all 3 nodes have no healthcheck, the ILB fails
open and sends requests to all pgbouncer nodes, which will likely result in
more connections to postgres than desired.

Work is ongoing to make this better (make systemd retry slower, and keep retrying
for longer, as we *really* want it to try and have this `consul lock` process
running)

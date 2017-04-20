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

Currently we are running PgBouncer directly on the database servers, without
managing it with Chef. This is a temporary setup until GitLab Enterprise Edition
supports PgBouncer (<https://gitlab.com/gitlab-org/omnibus-gitlab/merge_requests/1345>).

PgBouncer was installed using apt-get. The configuration files are located in
`/etc/pgbouncer`.

The port PgBouncer listens on is 6432.

## File Descriptor Limits

PgBouncer will typically open a lot of files and sockets. This requires an
adequate `ulimit` value to be set, otherwise PgBouncer may crash. To do so add
the following line to `/etc/default/pgbouncer`:

    ulimit -n 4096

Then restart PgBouncer.

## PgBouncer Commands

PgBouncer is controlled using systemd at the moment. The following commands are
available:

* `sudo systemctl restart pgbouncer`
* `sudo systemctl start pgbouncer`
* `sudo systemctl stop pgbouncer`
* `sudo systemctl reload pgbouncer`

Note that restarting PgBouncer will terminate existing connections immediately,
possibly leading to application errors.

You can also control PgBouncer when connected to it using its own set of
commands. See <http://pgbouncer.github.io/usage.html#admin-console> for more
information.

## Applying Changes

Almost all settings of PgBouncer can be adjusted by just reloading the
configuration file instead of restarting PgBouncer. Right now this means having
to adjust the configuration file manually, followed by running `sudo systemctl
reload pgbouncer`.

## Statistics

PgBouncer has its own internal set of statistics. To view these, log in to the
PgBouncer database:

    sudo gitlab-psql -h localhost -p 6432 -U pgbouncer -d pgbouncer

This will ask for a password, which you currently can find in
`/etc/pgbouncer/userlist.txt`. Once connected you can run various commands to
get statistics, see <https://pgbouncer.github.io/usage.html#admin-console> for
more information.

## Troubleshooting

### PgBouncer is dead but systemd doesn't restart it

This can happen when systemd thinks the process is still running. To solve this
you have to explicitly stop then start the process:

    sudo systemctl stop pgbouncer
    sudo systemctl start pgbouncer

### I think we need more connections, how can I check this?

Log in to the PgBouncer database, then run `show lists`. If `free_servers` is 0
this means you need more backend connections. If `free_clients` is 0 this means
you need more frontend connections. Both can be changed by reloading PgBouncer.

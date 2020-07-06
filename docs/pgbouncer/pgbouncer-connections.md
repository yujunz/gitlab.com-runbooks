# PgBouncer connection management and troubleshooting

We use PgBouncer for connection pooling with the purpose of optimizing our usage
of database connections. This runbook includes some pointers on monitoring,
tuning and troubleshooting PgBouncer connectivity. For incident response see
[./pgbouncer-saturation.md](./pgbouncer/pgbouncer-saturation.md).

The main metrics dashboard for PgBouncer can be found at
https://dashboards.gitlab.net/d/pgbouncer-main/pgbouncer-overview?orgId=1. Of
particular interest is the `pgbouncer Connection Pooling` section, which allows
us to visualize connection usage trends on PgBouncer. An upwards trend in
saturation per node or per pool may indicate the need to tune our PgBouncer
setup.

## Connection pooling monitoring and tuning

If you identify a problematic pool or node you can drill down on each individual
instance by ssh-ing into the relevant PgBouncer (for read/write PgBouncers) or
Patroni (for read-only PgBouncers) node and querying the pgb console(s).

Running `show pools` in `pgb-console` allows us to see more details regarding
the interaction of clients with the connection pools. For example:

````
pgbouncer=# show pools;
      database       |    user    | cl_active | cl_waiting | sv_active | sv_idle | sv_used | sv_tested | sv_login | maxwait | maxwait_us |  pool_mode
---------------------+------------+-----------+------------+-----------+---------+---------+-----------+----------+---------+------------+-------------
 gitlabhq_production | gitlab     |      1051 |          0 |         5 |      20 |       3 |         0 |        0 |       0 |          0 | transaction
 gitlabhq_production | gitlab-app |         0 |          0 |         0 |       0 |       0 |         0 |        0 |       0 |          0 | transaction
 gitlabhq_production | pgbouncer  |         0 |          0 |         0 |       1 |       0 |         0 |        0 |       0 |          0 | transaction
 pgbouncer           | pgbouncer  |         2 |          0 |         0 |       0 |       0 |         0 |        0 |       0 |          0 | statement
(4 rows)
````

We're mainly interested in the connections of the `gitlab` user, as it's the one
used by our clients (web, git, api, sidekiq). A description of each column can
be found at https://www.pgbouncer.org/usage.html. Of particular interest is
`cl_waiting`: it indicates that a number of clients are attempting to execute a
transaction but PgBouncer couldn't assign a server connection to them right
away. If `cl_waiting` is trending upwards it could indicate a number of issues:

- Connections are getting hogged somehow. We should investigate if there are
  long-running SQL queries/transactions that could be causing this.
- We're reaching client saturation and we need to provide more server
  connections. Notice that doing so increases the number of _real_ connections
  to the underlying database, so we also need to make sure the database is
  correctly tuned for that increase and that we don't run into any limits (for
  more details, see https://www.postgresql.org/docs/11/kernel-resources.html).
  To achieve this, increase `pool_size` in the relevant chef-repo role for the
  affected pool:
    - `roles/gprd-base-db-patroni.json` for read-only PgBouncers
    - `roles/gprd-base-db-pgbouncer-sidekiq.json` for read-write
      Sidekiq-specific PgBouncers
    - `roles/gprd-base-db-pgbouncer.json` for read-write general purpose
      PgBouncers
- Verify if the number of sv_idle is high when the cl_waiting is queueing high, that could represent a problem how the application is managing the connections, not finishing the connections when idle, generating a possible misusage of resources.

## Resource saturation

PgBouncer is
[single-threaded](https://www.pgbouncer.org/config.html#low-level-network-settings),
so an increased workload may lead to CPU saturation. CPU saturation can be
visualized on [this
graph](https://dashboards.gitlab.net/d/pgbouncer-main/pgbouncer-overview?viewPanel=29&orgId=1).
First you should check if there's an incident causing the resource saturation
(see [./pgbouncer-saturation.md](./pgbouncer-saturation.md) for that purpose).
If instead we're experiencing an organic increase in PgBouncer load we can scale
horizontally either by adding more PgBouncer processes in read-only nodes or by
adding new PgBouncer nodes for the primary database (see
[(./pgbouncer-add-instance.md](./pgbouncer-add-instance.md)).

## Troubleshooting

### Primary database connections are not working.

Verify that the configuration exists in the `databases.ini`

    sudo cat /var/opt/gitlab/pgbouncer/databases.ini

If there is a configuration there for the `host=master.patroni.service.consul`
section, log into pgbouncer itself. Verify that the configuration has been
loaded (from within pgbouncer's console):

```
show databases;
```

the entry should look something like this:

```
pgbouncer=# show databases;
          name           |             host              | port |        database         | force_user | pool_size | reserve_pool | pool_mode | max_connections | current_connections | paused | disabled
-------------------------+-------------------------------+------+-------------------------+------------+-----------+--------------+-----------+-----------------+---------------------+--------+----------
 gitlabhq_geo_production |                               | 5432 | gitlabhq_geo_production |            |         1 |            5 |           |               0 |                   0 |      0 |        0
 gitlabhq_production     | master.patroni.service.consul | 5432 | gitlabhq_production     |            |        50 |            5 |           |               0 |                  25 |      0 |        0
 pgbouncer               |                               | 6432 | pgbouncer               | pgbouncer  |         2 |            0 | statement |               0 |                   0 |      0 |        0
(3 rows)
```

Where the `host` field has the same value as the `databases.ini`.

Verify that the patroni **service** in consul is resolvable via DNS and that the
host it resolves to is reachable. For this purpose you can simply use `ping
master.patroni.service.consul`. You should see something like the following:

````
pgbouncer-01-db-gprd.c.gitlab-production.internal:~$ ping master.patroni.service.consul
PING master.patroni.service.consul (10.220.16.111) 56(84) bytes of data.
64 bytes from patroni-11-db-gprd.c.gitlab-production.internal (10.220.16.111): icmp_seq=1 ttl=64 time=1.29 ms
64 bytes from patroni-11-db-gprd.c.gitlab-production.internal (10.220.16.111): icmp_seq=2 ttl=64 time=0.236 ms
```

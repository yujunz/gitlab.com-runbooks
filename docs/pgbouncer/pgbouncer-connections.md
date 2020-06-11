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

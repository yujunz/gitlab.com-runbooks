# Operations

This page has historically been about PostgreSQL HA with repmgr. These
parts have been removed since we switched to Patroni. Still valid
information has been retained.

## Consul

### Health

* Show consul members. Any error can indicate an issue with consul. Can be run from any node connected to the consul cluster. If cluster issues are expected, run from consul servers to check.

   ```shell
   # /opt/gitlab/embedded/bin/consul members
   ```

### Commands
* To force an update to `/var/opt/gitlab/consul/databases.ini` on the pgbouncer server

   ```shell
   # gitlab-ctl restart consul
   ```

## Pgbouncer

### Health

* `/var/opt/gitlab/consul/databases.ini` should exist, and it should have a value for `host=XXXXXX`

* Connect to the admin console with `gitlab-ctl pgb-console` -- Password should be in 1 Password

  * Check database configuration. Check `host` column, and `current_connections` first

    ```shell
    pgbouncer=# show databases;
            name         |     host      | port |      database       | force_user | pool_size | reserve_pool | pool_mode | max_connections | current_connections | paused | disabled
    ---------------------+---------------+------+---------------------+------------+-----------+--------------+-----------+-----------------+---------------------+--------+----------
     gitlabhq_production | PRIMRAY_HOST  | 5432 | gitlabhq_production |            |       100 |            5 |           |               0 |                   1 |      0 |        0
     pgbouncer           |               | 6432 | pgbouncer           | pgbouncer  |         2 |            0 | statement |               0 |                   0 |      0 |        0
     (2 rows)
    ```

  * Check for client connections

    ```shell
    pgbouncer=# show clients;
     type |   user    |      database       | state  |   addr    | port  | local_addr | local_port |    connect_time     |    request_time     |  wait   | wait_us |    ptr    | link | remote_pid | tls
    ------+-----------+---------------------+--------+-----------+-------+------------+------------+---------------------+---------------------+---------+---------+-----------+------+------------+-----
     C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 58448 | 127.0.0.1  |       6432 | 2018-06-04 19:19:36 | 2018-06-06 18:20:58 |       0 |       0 | 0x228e8f0 |      |          0 |
    ...
    ```

  * Check for server connections

    ```shell
    pgbouncer=# show servers;
     type |  user  |      database       | state |     addr      | port |  local_addr    | local_port |    connect_time     |    request_time     | wait | wait_us |    ptr    | link | remote_pid | tls
    ------+--------+---------------------+-------+---------------+------+----------------+------------+---------------------+---------------------+------+---------+-----------+------+------------+-----
     S    | gitlab | gitlabhq_production | idle  | PRIMARY_HOST  | 5432 | PGBOUNCER_HOST |      48064 | 2018-06-06 19:57:26 | 2018-06-06 19:57:26 |    0 |       0 | 0x22980d0 |      |      29546 |
    ...
    ```

## PostgreSQL

### Health

* Connect to the db console

    ```shell
    # gitlab-psql -d gitlabhq_production
    ```

* Check if a node thinks it is a primary or a standby

    ```shell
    # gitlab-psql -d template1
    template1# select * from pg_is_in_recovery();
    ...
    ```
    `f` indicates the node is a primary
    `t` indicates the node is a standby

* If replication isn't working, check that the replication slots exist and are active. If restart_lsn does not equal pg_current_xlog_location, there is some replication lag.

    ```shell
    # gitlab-psql -d template1
    template1=# select * from pg_replication_slots ; select * from pg_current_xlog_location();
           slot_name                                 | plugin | slot_type | datoid | database | active | active_pid | xmin | catalog_xmin | restart_lsn | confirmed_flush_lsn
    -------------------------------------------------+--------+-----------+--------+----------+--------+------------+------+--------------+-------------+---------------------
     patroni_04_db_gprd_c_gitlab_production_internal |        | physical  |        |          | t      |      28881 |      |              | AD/59000060 |
    ...

    pg_current_xlog_location
   --------------------------
    AD/5C000060
   (1 row)

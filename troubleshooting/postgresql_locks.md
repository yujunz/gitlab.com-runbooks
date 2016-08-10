# Locks in PostgreSQL or Stuck Sidekiq workers

## Symptoms

* You see an alert like

```
db4.cluster.gitlab.com service POSTGRES_LONGEST_QUERY is OK with some DML query (UPDATE, DELETE, INSERT)
```

* Or there will be a lot of items in the queues on page https://gitlab.com/admin/sidekiq/queues

* Or there will be non empty result from the following command (stopping queries)

```
$  bundle exec knife ssh -a ipaddress role:gitlab-cluster-worker 'ps -U git -o args | grep sidekiq' | grep stopping
```

## Possible checks

* Go to PostgreSQL and if result for the following query is not empty to check that tables are not locked

```
SELECT clock_timestamp(), pg_class.relname, pg_locks.locktype, pg_locks.database,
pg_locks.relation, pg_locks.page, pg_locks.tuple, pg_locks.virtualtransaction,
pg_locks.pid, pg_locks.mode, pg_locks.granted
FROM pg_locks JOIN pg_class ON pg_locks.relation = pg_class.oid
WHERE relname !~ '^pg_' and relname <> 'active_locks' and page is not null order by pid;
```

## Please gather data!

* Capture which queries are being executed right now please
  * turn into root `sudo su -`
  * run the queries script `./get_all_queries.sh > queries.log`
  * run the locked queries script `./get_locked_queries.sh > locked-queries.log`

## Resolution

* go to PostgreSQL console
* run following query
```
SELECT pg_terminate_backend(pg_locks.pid) FROM pg_locks JOIN pg_class ON pg_locks.relation = pg_class.oid WHERE relname !~ '^pg_' and relname <> 'active_locks' and page is not null order by pid;
```

* there also can be long running DML query in `pg_stat_activity`

```
select pid, state, query_start, (now() - query_start) as duration, substring(query, 0, 120) from pg_stat_activity where state = 'active' and (now() - query_start) > '1 seconds'::interval order by duration desc limit 15;
```

take its pid and run following SQL query

```
select pg_cancel_backend(:pid);
```


## Post checks

* Result for the following query must be empty
```
SELECT clock_timestamp(), pg_class.relname, pg_locks.locktype, pg_locks.database,
pg_locks.relation, pg_locks.page, pg_locks.tuple, pg_locks.virtualtransaction,
pg_locks.pid, pg_locks.mode, pg_locks.granted
FROM pg_locks JOIN pg_class ON pg_locks.relation = pg_class.oid
WHERE relname !~ '^pg_' and relname <> 'active_locks' and page is not null order by pid;
```

* `$  bundle exec knife ssh -a ipaddress role:gitlab-cluster-worker 'ps -U git -o args | grep sidekiq' | grep stopping` must be empty

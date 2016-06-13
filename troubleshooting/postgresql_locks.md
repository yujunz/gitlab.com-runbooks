# Locks in PostgreSQL or Stuck Sidekiq workers

## Symptoms

* You see an alert like

```
db4.cluster.gitlab.com service POSTGRES_LONGEST_QUERY is OK with some DML query (UPDATE, DELETE, INSERT)
```

* Or there will be a lot of items in the queues on page https://gitlab.com/admin/sidekiq/queues

* Or there will be stopping near sidekiq processes

```
$  bundle exec knife ssh -a ipaddress role:gitlab-cluster-worker 'ps -U git -o args | grep sidekiq'
40.84.0.225     sidekiq 4.1.2 gitlab-rails [25 of 25 busy]
13.68.20.218    sidekiq 4.1.2 gitlab-rails [25 of 25 busy]
40.84.31.149    sidekiq 4.1.2 gitlab-rails [23 of 25 busy]
40.84.63.177    sidekiq 4.1.2 gitlab-rails [24 of 25 busy]
40.84.6.191     sidekiq 4.1.2 gitlab-rails [24 of 25 busy]
40.84.62.218    sidekiq 4.1.2 gitlab-rails [24 of 25 busy]
40.84.62.244    sidekiq 4.1.2 gitlab-rails [25 of 25 busy]
40.79.46.26     sidekiq 4.1.2 gitlab-rails [25 of 25 busy]
13.68.21.26     sidekiq 4.1.2 gitlab-rails [25 of 25 busy]
40.84.58.172    sidekiq 4.1.2 gitlab-rails [25 of 25 busy]
40.84.59.249    sidekiq 4.1.2 gitlab-rails [25 of 25 busy]
40.84.58.110    sidekiq 4.1.2 gitlab-rails [25 of 25 busy]
40.79.46.123    sidekiq 4.1.2 gitlab-rails [25 of 25 busy]
40.84.3.129     sidekiq 4.1.2 gitlab-rails [23 of 25 busy] stopping
104.208.241.215 sidekiq 4.1.2 gitlab-rails [17 of 25 busy]
104.208.242.23  sidekiq 4.1.2 gitlab-rails [24 of 25 busy]
104.208.241.47  sidekiq 4.1.2 gitlab-rails [19 of 25 busy]
40.79.42.83     sidekiq 4.1.2 gitlab-rails [25 of 25 busy]
40.79.45.48     sidekiq 4.1.2 gitlab-rails [25 of 25 busy] stopping
40.79.75.98     sidekiq 4.1.2 gitlab-rails [25 of 25 busy]
```

## Possible checks

* Go to PostgreSQL and if result for the following query is not empty

```
SELECT clock_timestamp(), pg_class.relname, pg_locks.locktype, pg_locks.database,
pg_locks.relation, pg_locks.page, pg_locks.tuple, pg_locks.virtualtransaction,
pg_locks.pid, pg_locks.mode, pg_locks.granted
FROM pg_locks JOIN pg_class ON pg_locks.relation = pg_class.oid
WHERE relname !~ '^pg_' and relname <> 'active_locks' and page is not null order by pid;
```


## Resolution

* go to PostgreSQL console
* run following query
```
SELECT pg_cancel_backend(pg_locks.pid) FROM pg_locks JOIN pg_class ON pg_locks.relation = pg_class.oid WHERE relname !~ '^pg_' and relname <> 'active_locks' and page is not null order by pid;
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

* `$  bundle exec knife ssh -a ipaddress role:gitlab-cluster-worker 'ps -U git -o args | grep sidekiq'` must be without `stopping` word

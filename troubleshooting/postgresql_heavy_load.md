# Postgresql on heavy load

## First and foremost

*Don't Panic*

## Symptoms

* Message in alerts channel _Check_MK: db4.cluster.gitlab.com service CPU load is CRITICAL_
* Pingdom alert GitLab.com DOWN - this is because having an unresponsive database takes GitLab down.

## Possible checks

* Checkmk
  * [db4](https://checkmk.gitlap.com/gitlab/pnp4nagios/index.php/graph?host=db4.cluster.gitlab.com&srv=CPU_load&theme=multisite&baseurl=../check_mk/)
  * [db5](https://checkmk.gitlap.com/gitlab/pnp4nagios/index.php/graph?host=db5.cluster.gitlab.com&srv=CPU_load&theme=multisite&baseurl=../check_mk/)
* The graph should look like this:
  * ![Heavy load on postgresql](img/postgresql-heavy-load.png)
* If the host is responsive
  * Login into the database
    * `sudo su - gitlab-psql`
    * `psql -h /var/opt/gitlab/postgresql gitlabhq_production`
  * Sample first 15 queries that are active and taking a lot of time (over 1 second) sorted by duration in descending order, note that only first 120 symbols or query are shown - keep this sample
    * `select pid, state, query_start, (now() - query_start) as duration, substring(query, 0, 120) from pg_stat_activity where state = 'active' and (now() - query_start) > '1 seconds'::interval order by duration desc limit 15;`
  * Measure queries activity for a bit to see if there is any change, usually there are circa 600 records in activity, so don't be scared for such number
    * `psql -h /var/opt/gitlab/postgresql gitlabhq_production -c 'SELECT count(*) FROM pg_stat_activity;'`

### Please gather data!

Since this is still an unsolved problem, we will need to gather all the data we can, to do so, run the following commands to gather as much data as possible

* Get a copy of the _current_ log file to later check reported slow queries.
  * `sudo cp /var/log/gitlab/postgresql/current ~`
* Get a sample of virtual memory usage - this is useful to see if the host is suffering from memory usage/[thrashing](https://en.wikipedia.org/wiki/Thrashing_\(computer_science\))
  * `vmstat -S M 1 10`
* Get a sample of server load
  * `while sleep 5; do uptime; done`
* Get as sample of processes executing:
  * `ps auxf`
* Keep a copy of the sample queries from the pre-checks
  * turn into root `sudo su -`
  * run the queries script `./get_all_queries.sh > queries.log`

## Resolution

* The simplest/least intrusive resolution that has worked really well was to raise the downtime page from your chef repo
  * `bundle exec knife ssh -a ipaddress 'role:gitlab-cluster-worker' 'sudo gitlab-ctl deploy-page up'`
  * monitor load, after it goes down to roughly 15 take the page down
  * `bundle exec knife ssh -a ipaddress 'role:gitlab-cluster-worker' 'sudo gitlab-ctl deploy-page down'`
* Killing queries that are causing the load
  * gentle kill
    * `select pg_cancel_backend(pid) from pg_stat_activity where state = 'active' and (now() - query_start) > '30 seconds'::interval;` - will return True if succeeds, use the next one if it is not enough
  * hard kill
    * `select pg_terminate_backend(pid) from pg_stat_activity where state = 'active' and (now() - query_start) > '30 seconds'::interval;`
* This can also be done killing all the queries that are taking too long (30 seconds)
  * ``
* The next step if it is not recovering is to bounce the service, this will prevent having a failover
  * `sudo gitlab-ctl postgresql restart`
* If this is not working, bounce the whole server - this will trigger a set of failures in CheckMK and will drop replication. Check post actions.
  * `sudo restart`
  * Or do it from the Azure console

## Post actions

If the service or the server has been bounced, we will need to recover the replication

### Recover replication from slave server

Refer to [Postgresql replication is lagging or dropped](troubleshooting/postgresql_replication.md) runbook

### Cleanup in Checkmk

In the alerts channel there may be messages like _Check_MK: db4.cluster.gitlab.com service PostgreSQL DB template0 Statistics is UNKNOWN_

This is a side effect of failing over to the other database server, the original one will not be replying to status queries.

It is not critical, but it is a great source of noise.

The way to fix this is to log into CheckMK and force the reload of the host metrics.

### Sample queries scripts

* get_all_queries.sh
``` bash
#!/bin/bash
su - gitlab-psql -c "/opt/gitlab/embedded/bin/psql -h /var/opt/gitlab/postgresql template1 <<EOF
\x on ;
SELECT pid, state, age(clock_timestamp(), query_start) as duration, query
FROM pg_stat_activity
WHERE query != '<IDLE>' AND query NOT ILIKE '%pg_stat_activity%' AND state != 'idle'
ORDER BY age(clock_timestamp(), query_start) DESC;
EOF"
```

* get_slow_queries.sh
```
#!/bin/bash
su - gitlab-psql -c "/opt/gitlab/embedded/bin/psql -h /var/opt/gitlab/postgresql template1 <<EOF
\x on ;
SELECT pid, state, age(clock_timestamp(), query_start) as duration, query
FROM pg_stat_activity
WHERE query != '<IDLE>' AND query NOT ILIKE '%pg_stat_activity%' AND state != 'idle' AND age(clock_timestamp(), query_start) > '00:01:00'
ORDER BY age(clock_timestamp(), query_start) DESC;
EOF"
```

* terminate_slow_queries.sh
```
#!/bin/bash
su - gitlab-psql -c "/opt/gitlab/embedded/bin/psql -h /var/opt/gitlab/postgresql template1 <<EOF
SELECT pg_terminate_backend (pid)
FROM pg_stat_activity
WHERE query != '<IDLE>' AND query NOT ILIKE '%pg_stat_activity%' AND state != 'idle' AND age(clock_timestamp(), query_start) > '00:04:00';
EOF"
```

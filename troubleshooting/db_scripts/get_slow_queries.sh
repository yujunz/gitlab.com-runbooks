#!/bin/bash
su - gitlab-psql -c "/opt/gitlab/embedded/bin/psql -h /var/opt/gitlab/postgresql template1 <<EOF
\\x on
SELECT pid, application_name, client_addr, state, age(clock_timestamp(), query_start) as duration, query
FROM pg_stat_activity
WHERE query != '<IDLE>' AND query NOT ILIKE '%pg_stat_activity%' AND state != 'idle' AND age(clock_timestamp(), query_start) > '00:01:00'
ORDER BY age(clock_timestamp(), query_start) DESC;
EOF"

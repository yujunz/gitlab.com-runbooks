#!/bin/bash
su - gitlab-psql -c "/opt/gitlab/embedded/bin/psql -h /var/opt/gitlab/postgresql template1 <<EOF
\x on
SELECT pid, application_name, client_addr, query, age(clock_timestamp(), query_start) AS waiting_duration
FROM pg_catalog.pg_stat_activity WHERE  waiting
ORDER BY age(clock_timestamp(), query_start) DESC;
EOF"
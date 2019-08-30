#!/bin/bash
su - gitlab-psql -c "/opt/gitlab/embedded/bin/psql -h /var/opt/gitlab/postgresql template1 <<EOF
\x on
SELECT pg_terminate_backend (pid)
FROM pg_stat_activity
WHERE query != '<IDLE>' AND query NOT ILIKE '%pg_stat_activity%' AND state != 'idle' AND age(clock_timestamp(), query_start) > '00:04:00';
EOF"

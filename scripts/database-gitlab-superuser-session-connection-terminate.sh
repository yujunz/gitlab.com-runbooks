#! /usr/bin/env bash

# database-gitlab-superuser-session-connection-terminate.sh
#
# This script will terminate session connections for the gitlab-superuser.
#
# Example:
#
# /root/scripts/database-gitlab-superuser-session-connection-terminate.sh --dry-run
# /root/scripts/database-gitlab-superuser-session-connection-terminate.sh --wet-run

# Immediately exit if any command has a non-zero exit status.
set -e

# Immediately exit if any variable previously undefined is referenced.
set -u

# Do not mask errors in a pipeline
set -o pipefail

run_mode="${1:---dry-run}"

old_username='gitlab-superuser'

current_host=$(hostname)

# Expected non-zero status
set +e
read -r -d '' terminate_database_connection_session_command <<EOF
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE usename = '${old_username}';
EOF
set -e

function psql_command() {
  /usr/local/bin/gitlab-psql --pset=pager=off --command "$1"
}

function is_patroni_leader() {
  node_fqdn=$(hostname --fqdn)
  patroni_leader_node_fqdn=$(/usr/local/bin/gitlab-patronictl list --format json 2>/dev/null | jq --raw-output '.[] | select(.Role=="Leader").Member')
  test "${node_fqdn}" == "${patroni_leader_node_fqdn}"
  return $?
}

function check_if_running_on_patroni_leader() {
  # Allow non-zero status
  set +e
  is_patroni_leader
  local is_leader=$?
  set -e
  if [[ "${is_leader}" == '0' ]]; then
    echo "INFO: The current host ${current_host} IS the patroni leader"
  else
    echo "WARNING: The current host ${current_host} is NOT the patroni leader"
  fi
}

function list_all_users() {
  echo "Listing all users in the database"
  psql_command '\du'
}

function list_all_connections_per_user() {
  echo "Listing all connections per user"
  psql_command 'SELECT usename, count(1) FROM pg_stat_activity GROUP BY 1;'
}

function psql_whoami() {
  echo "Showing who I am"
  psql_command 'SELECT usename FROM pg_stat_activity WHERE pid = pg_backend_pid();'
}

function list_all_connections_except_my_session() {
  echo "Listing all connections except my session"
  psql_command 'SELECT pid, usename FROM pg_stat_activity WHERE pid <> pg_backend_pid();'
}

function terminate_database_connection_session() {
  echo "Terminating database session connection(s) for user role ${old_username}"
  if [[ "${run_mode}" == "--wet-run" ]]; then
    echo "Executing psql command: ${terminate_database_connection_session_command}"
    set -x
    psql_command "${terminate_database_connection_session_command}"
    set +x
  else
    echo "[Dry-run] Would have executed psql command: ${terminate_database_connection_session_command}"
    echo "[Dry-run] Re-execute with the --wet-run parameter to actually execute commands to make modifications"
  fi
}

list_all_users
list_all_connections_per_user
list_all_connections_except_my_session
psql_whoami
check_if_running_on_patroni_leader
terminate_database_connection_session

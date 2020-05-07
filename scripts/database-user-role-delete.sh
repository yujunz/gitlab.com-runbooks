#! /usr/bin/env bash

# database-user-role-delete.sh
#
# This script will delete a user role with the given name from the postgres database.
#
# Example:
#
# /root/scripts/database-user-role-delete.sh gitlab-superuser-20200427_181922 --dry-run
# /root/scripts/database-user-role-delete.sh gitlab-superuser-20200427_181922 --wet-run
#

# Immediately exit if any command has a non-zero exit status.
set -e

# Immediately exit if any variable previously undefined is referenced.
set -u

# Do not mask errors in a pipeline
set -o pipefail

username_of_role_to_delete="${1}"
run_mode="${2:---dry-run}"

if [[ -z "${username_of_role_to_delete}" ]]; then
  echo "Usage: database-user-role-delete <username> --[dry|wet]-run"
fi

current_host=$(hostname)

# Expected non-zero status
set +e

read -r -d '' drop_role_command <<EOF
DROP ROLE "${username_of_role_to_delete}";
EOF

read -r -d '' drop_owned_command <<EOF
DROP OWNED BY "${username_of_role_to_delete}";
EOF

read -r -d '' list_tables_owned_by_user <<EOF
SELECT * FROM pg_tables t WHERE t.tableowner = '${username_of_role_to_delete}';
EOF

read -r -d '' terminate_database_connection_session_command <<EOF
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE usename = '${username_of_role_to_delete}';
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

function exit_unless_running_on_patroni_leader() {
  # Allow non-zero status
  set +e
  is_patroni_leader
  local is_leader=$?
  set -e
  if [[ "${is_leader}" != '0' ]]; then
    echo "FATAL: The current host ${current_host} is NOT the patroni leader; aborting"
    exit
  fi
  echo "INFO: The current host ${current_host} IS the patroni leader"
}

function list_all_users() {
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

function show_user() {
  psql_command '\du' | grep " ${username_of_role_to_delete} "
}

function find_user_role() {
  # Allow non-zero status
  set +e
  show_user
  user_tuple=$?
  set -e
  if [[ "${user_tuple}" == '0' ]]; then
    echo "The user ${username_of_role_to_delete} role exists in the database"
  else
    echo "The user role does not exist in the database: ${username_of_role_to_delete}"
  fi
}

function exit_unless_user_role_exists() {
  # Allow non-zero status
  set +e
  show_user
  user_tuple=$?
  set -e
  if [[ "${user_tuple}" != '0' ]]; then
    echo "FATAL: Role '${username_of_role_to_delete}' does not exist in the database; aborting"
    exit
  fi
}

function list_owned_tables() {
  echo "Listing all tables owned by: ${username_of_role_to_delete}"
  echo "Executing psql command: ${list_tables_owned_by_user}"
  set -x
  psql_command "${list_tables_owned_by_user}"
  set +x
}

function drop_owned_objects() {
  echo "Dropping objects (privilege settings) owned by user ${username_of_role_to_delete}"
  if [[ "${run_mode}" == "--wet-run" ]]; then
    echo "Executing psql command: ${drop_owned_command}"
    set -x
    psql_command "${drop_owned_command}"
    set +x
  else
    echo "[Dry-run] Would have executed psql command: ${drop_owned_command}"
    echo "[Dry-run] Re-execute with the --wet-run parameter to actually execute commands to make modifications"
  fi
}

function terminate_database_connection_session() {
  echo "Terminating database session connection(s) for user role ${username_of_role_to_delete}"
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

function delete_user_role() {
  echo "Deleting user ${username_of_role_to_delete} role"
  if [[ "${run_mode}" == "--wet-run" ]]; then
    echo "Executing psql command: ${drop_role_command}"
    set -x
    psql_command "${drop_role_command}"
    set +x
  else
    echo "[Dry-run] Would have executed psql command: ${drop_role_command}"
    echo "[Dry-run] Re-execute with the --wet-run parameter to actually execute commands to make modifications"
  fi
}

list_all_users
list_all_connections_per_user
list_all_connections_except_my_session
psql_whoami
exit_unless_running_on_patroni_leader
find_user_role
list_owned_tables
exit_unless_user_role_exists
drop_owned_objects
terminate_database_connection_session
delete_user_role

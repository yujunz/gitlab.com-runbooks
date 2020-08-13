#! /usr/bin/env bash

# database-gitlab-superuser-user-role-password-update.sh
#
# This script will update the password for a gitlab-superuser user account.
#
# Make sure to set the NEW_PASSWORD environment variable appropriately.
#
# Alternatively, ensure the existence of a file named 'new_password.sh' in
# the same directory as this script that exports the appropriately set
# NEW_PASSWORD variable.
#
# Example:
#
# /root/scripts/database-gitlab-superuser-user-role-password-update.sh --dry-run
# /root/scripts/database-gitlab-superuser-user-role-password-update.sh --wet-run

# Immediately exit if any command has a non-zero exit status.
set -e

# Immediately exit if any variable previously undefined is referenced.
set -u

# Do not mask errors in a pipeline
set -o pipefail

run_mode="${1:---dry-run}"

script_dir_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
[[ -f "${script_dir_path}/.new_password.sh" ]] && source "${script_dir_path}/.new_password.sh"

username='gitlab-superuser'
# Disable shellcheck warning for "Possible misspelling"
# Here the variable NEW_PASSWORD is expected to be defined in one's environment.
# shellcheck disable=SC2153
new_password="${NEW_PASSWORD}"

redacted_password=${new_password:0:4}
redacted_password="${redacted_password}...[redacted]..."

current_host=$(hostname)

# Expected non-zero status
set +e

read -r -d '' update_user_password_command <<EOF
ALTER ROLE "${username}" WITH
ENCRYPTED PASSWORD '${new_password}';
EOF

read -r -d '' update_user_password_redacted_command <<EOF
ALTER ROLE "${username}" WITH
ENCRYPTED PASSWORD '${redacted_password}';
EOF

read -r -d '' terminate_database_connection_session_command <<EOF
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE usename = '${username}';
EOF

set -e

function psql_command() {
  /usr/local/bin/gitlab-psql --pset=pager=off --command "$1"
}

function update_user_password() {
  echo "Updating password for user: ${username}"
  if [[ "${run_mode}" == "--wet-run" ]]; then
    echo "Executing psql command: ${update_user_password_redacted_command}"
    # Ensure that the following command invocation is not displayed
    set +x
    psql_command "${update_user_password_command}"
  else
    echo "[Dry-run] Would have executed psql command: ${update_user_password_redacted_command}"
    echo "[Dry-run] Re-execute with the --wet-run parameter to actually execute commands to make modifications"
  fi
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
  echo "Terminating database session connection(s) for user role ${username}"
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
exit_unless_running_on_patroni_leader
update_user_password
terminate_database_connection_session

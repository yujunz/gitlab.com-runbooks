#! /usr/bin/env bash

# database-gitlab-superuser-user-role-create.sh
#
# This script will create a new gitlab-superuser user account.
#
# Make sure to set the NEW_PASSWORD environment variable appropriately.
#
# Alternatively, ensure the existence of a file named 'new_password.sh' in
# the same directory as this script that exports the appropriately set
# NEW_PASSWORD variable.
#
# Example:
#
# /root/scripts/database-gitlab-superuser-user-role-create.sh --dry-run
# /root/scripts/database-gitlab-superuser-user-role-create.sh --wet-run

# Immediately exit if any command has a non-zero exit status.
set -e

# Immediately exit if any variable previously undefined is referenced.
set -u

# Do not mask errors in a pipeline
set -o pipefail

run_mode="${1:---dry-run}"

script_dir_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
[[ -f "${script_dir_path}/.new_password.sh" ]] && source "${script_dir_path}/.new_password.sh"

old_username='gitlab-superuser'
new_username="${old_username}-$(date --utc +%Y%m%d_%H%M%S)"
# Disable shellcheck warning for "Possible misspelling"
# Here the variable NEW_PASSWORD is expected to be defined in one's environment.
# shellcheck disable=SC2153
new_password="${NEW_PASSWORD}"

redacted_password=${new_password:0:4}
redacted_password="${redacted_password}...[redacted]..."

current_host=$(hostname)

# Expected non-zero status
set +e

read -r -d '' create_user_command <<EOF
CREATE USER "${new_username}" WITH
SUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN REPLICATION NOBYPASSRLS
CONNECTION LIMIT 10
ENCRYPTED PASSWORD '${new_password}';
EOF

read -r -d '' create_user_redacted_command <<EOF
CREATE USER "${new_username}" WITH
SUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN REPLICATION NOBYPASSRLS
CONNECTION LIMIT 10
ENCRYPTED PASSWORD '${redacted_password}';
EOF

read -r -d '' grant_all_command <<EOF
GRANT ALL PRIVILEGES ON DATABASE gitlabhq_production TO "${new_username}";
EOF

read -r -d '' list_tables_owned_by_user <<EOF
SELECT * FROM pg_tables t WHERE t.tableowner = '${old_username}';
EOF

read -r -d '' reassigned_owned_command <<EOF
REASSIGN OWNED BY "${old_username}" TO "${new_username}";
EOF

read -r -d '' alter_role_statement_timeout_command <<EOF
ALTER ROLE "${new_username}" SET statement_timeout TO '0';
EOF

set -e

function psql_command() {
  /usr/local/bin/gitlab-psql --pset=pager=off --command "$1"
}

function add_user() {
  echo "Adding new user: ${new_username}"
  if [[ "${run_mode}" == "--wet-run" ]]; then
    echo "Executing psql command: ${create_user_redacted_command}"
    # Ensure that the following command invocation is not displayed
    set +x
    psql_command "${create_user_command}"
  else
    echo "[Dry-run] Would have executed psql command: ${create_user_redacted_command}"
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
  psql_command '\du'
}

function show_new_user() {
  psql_command '\du' | grep " ${new_username} "
}

function find_new_gitlab_superuser_role() {
  # Allow non-zero status
  set +e
  show_new_user
  new_user_tuple=$?
  set -e
  if [[ "${new_user_tuple}" == '1' ]]; then
    echo "The new ${new_username} role has not yet been added to the database"
  else
    echo "A new role has been added to the database: ${new_username}"
  fi
}

function grant_all_privileges() {
  echo "Granting all privileges to: ${new_username}"
  if [[ "${run_mode}" == "--wet-run" ]]; then
    echo "Executing psql command: ${grant_all_command}"
    set -x
    psql_command "${grant_all_command}"
    set +x
  else
    echo "[Dry-run] Would have executed psql command: ${grant_all_command}"
    echo "[Dry-run] Re-execute with the --wet-run parameter to actually execute commands to make modifications"
  fi
}

function list_owned_tables() {
  echo "Listing all tables owned by: ${new_username}"
  echo "Executing psql command: ${list_tables_owned_by_user}"
  set -x
  psql_command "${list_tables_owned_by_user}"
  set +x
}

# This does not appear to be necessary, it is left here as
# documentation of how to accomplish this.
function reassign_owned_objects() {
  echo "Re-assigning ownership settings for ${old_username} to ${new_username}"
  if [[ "${run_mode}" == "--wet-run" ]]; then
    echo "Executing psql command: ${reassigned_owned_command}"
    set -x
    psql_command "${reassigned_owned_command};"
    set +x
  else
    echo "[Dry-run] Would have executed psql command: ${reassigned_owned_command}"
    echo "[Dry-run] Re-execute with the --wet-run parameter to actually execute commands to make modifications"
  fi
}

function set_statement_timeout_for_role() {
  echo "Setting statement_timeout to 0 for role: ${new_username} "
  if [[ "${run_mode}" == "--wet-run" ]]; then
    echo "Executing psql command: ${alter_role_statement_timeout_command}"
    set -x
    psql_command "${alter_role_statement_timeout_command};"
    set +x
  else
    echo "[Dry-run] Would have executed psql command: ${alter_role_statement_timeout_command}"
    echo "[Dry-run] Re-execute with the --wet-run parameter to actually execute commands to make modifications"
  fi
}

list_all_users
exit_unless_running_on_patroni_leader
add_user
grant_all_privileges
list_owned_tables
# This does not appear to be necessary; preserving for instructional purposes
# reassign_owned_objects
set_statement_timeout_for_role
find_new_gitlab_superuser_role

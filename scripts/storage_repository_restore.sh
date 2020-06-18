#! /usr/bin/env bash

# Example usage:
#
# sudo /var/opt/gitlab/scripts/storage_repository_restore.sh --dry-run=yes '@hashed/XX/XX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
# sudo /var/opt/gitlab/scripts/storage_repository_restore.sh --dry-run=yes '@hashed/4a/68/4a68b75506effac26bc7660ffb4ff46cbb11ba00ed4795c1c5f0125f256d7f6a'
# sudo /var/opt/gitlab/scripts/storage_repository_restore.sh --dry-run=no '@hashed/4a/68/4a68b75506effac26bc7660ffb4ff46cbb11ba00ed4795c1c5f0125f256d7f6a'

# Immediately exit if any command has a non-zero exit status.
set -e

# Immediately exit if any variable previously undefined is referenced.
set -u

# Ensure that the return value of a pipeline is the value of the last (rightmost) command to exit with a non-zero status
set -o pipefail

EXPECTED_HASHED_STORAGE_DISK_PATH_LENGTH=78
REPOSITORIES_DIR_PATH='/var/opt/gitlab/git-data/repositories'

dry_run='yes'
disk_path=''

function usage() {
  echo "Usage: ${0} --dry-run=<yes|no; default: yes> <repository_disk_path>"
  exit 0
}

function storage_repository_restore() {
  disk_path_length="${#disk_path}"
  if [[ $disk_path_length -ne $EXPECTED_HASHED_STORAGE_DISK_PATH_LENGTH || $disk_path == *".."* ]]; then
    echo "Error: The given disk path seems invalid: ${disk_path}"
    exit 1
  fi

  dir_path=$(dirname "${REPOSITORIES_DIR_PATH}/${disk_path}")
  repo_name=$(basename "${disk_path}")

  # Allow non-zero status
  set +e
  moved_git_path=$(find "${dir_path}" -maxdepth 1 -name "${repo_name}+*+moved+*.git" | grep -v wiki)
  set -e
  if [[ -z "${moved_git_path}" || ! -d "${moved_git_path}" ]]; then
    echo "Error: No moved git repository found at given disk path: \
${REPOSITORIES_DIR_PATH}/${disk_path}+*+moved+*.git"
    if [[ "${dry_run}" != "no" && ! -d "${REPOSITORIES_DIR_PATH}/${disk_path}.git" ]]; then
      exit 1
    fi
    echo "Warning: The repository may have already been restored"
  fi

  # Allow non-zero status
  set +e
  moved_wiki_git_path=$(find "${dir_path}" -maxdepth 1 -name "${repo_name}+*+moved+*.wiki.git")
  set -e
  if [[ ! -d "${moved_wiki_git_path}" ]]; then
    echo "Warning: No moved wiki repository found at given disk path: \
${REPOSITORIES_DIR_PATH}/${disk_path}+*+moved+*.wiki.git"
  fi

  if [[ "${dry_run}" != "no" ]]; then
    if [[ -z "${moved_git_path}" || -z "${moved_wiki_git_path}" ]]; then
      exit 1
    fi
  fi

  original_git_path="${REPOSITORIES_DIR_PATH}/${disk_path}.git"
  original_wiki_git_path="${REPOSITORIES_DIR_PATH}/${disk_path}.wiki.git"

  cmd="mv \"${moved_git_path}\" \"${original_git_path}\"; \
  mv \"${moved_wiki_git_path}\" \"${original_wiki_git_path}\""
  dry_run_cmd="ls -ld \"${moved_git_path}\" \"${moved_wiki_git_path}\"; \
  ls -ld \"${original_git_path}\" \"${original_wiki_git_path}\""

  if [[ "${dry_run}" == "no" ]]; then
    echo "Executing command: ${cmd}"
    eval "${cmd}"
  else
    echo "[Dry-run] Would have executed command: ${cmd}"
    echo "[Dry-run] Instead will execute command: ${dry_run_cmd}"
    eval "${dry_run_cmd}"
  fi
}

function main() {
  storage_repository_restore
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run*)
      if [[ "$1" != *=* ]]; then
        shift
      fi
      dry_run="${1#*=}"
      ;;
    --help | -h | -?)
      usage
      ;;
    *)
      # >&2 printf "Error: Invalid argument\n"
      # exit 1
      disk_path=${1}
      ;;
  esac
  shift
done

main

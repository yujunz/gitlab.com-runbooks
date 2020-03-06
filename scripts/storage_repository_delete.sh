#! /usr/bin/env bash

# Example usage:
#
# sudo /var/opt/gitlab/scripts/storage_repository_delete.sh --dry-run=yes '@hashed/XX/XX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
# sudo /var/opt/gitlab/scripts/storage_repository_delete.sh --dry-run=yes '@hashed/4a/68/4a68b75506effac26bc7660ffb4ff46cbb11ba00ed4795c1c5f0125f256d7f6a'
# sudo /var/opt/gitlab/scripts/storage_repository_delete.sh --dry-run=no '@hashed/4a/68/4a68b75506effac26bc7660ffb4ff46cbb11ba00ed4795c1c5f0125f256d7f6a'

# Immediately exit if any command has a non-zero exit status.
set -e

# Immediately exit if any variable previously undefined is referenced.
set -u

EXPECTED_HASHED_STORAGE_DISK_PATH_LENGTH=78
REPOSITORIES_DIR_PATH='/var/opt/gitlab/git-data/repositories'

dry_run='yes'

function print_command_line_parameters() {
  echo "Command-line argument parameters:"
  for i in "${@}"; do echo "\"${i}\""; done
}

function usage() {
  echo "Usage: ${0} --dry-run=<yes|no; default: yes> <repository_disk_path>"
  exit 0
}

function storage_repository_delete() {
  disk_path_length="${#disk_path}"
  if [[ $disk_path_length -ne $EXPECTED_HASHED_STORAGE_DISK_PATH_LENGTH || $disk_path == *".."* ]]; then
    echo "Error: The given disk path seems invalid: ${disk_path}"
    exit 1
  fi

  git_path="${REPOSITORIES_DIR_PATH}/${disk_path}.git"
  if [[ ! -d "${git_path}" ]]; then
    echo "Error: No git repository found at given disk path: ${git_path}"
    exit 1
  fi

  wiki_git_path="${REPOSITORIES_DIR_PATH}/${disk_path}.wiki.git"
  if [[ ! -d "${wiki_git_path}" ]]; then
    echo "Warning: No wiki repository found at given disk path: ${wiki_git_path}"
  fi

  design_git_path="${REPOSITORIES_DIR_PATH}/${disk_path}.design.git"
  if [[ ! -d "${design_git_path}" ]]; then
    echo "Warning: No design repository found at given disk path: ${design_git_path}"
  fi

  cmd="rm -rf \"${git_path}\" \"${wiki_git_path}\" \"${design_git_path}\""
  dry_run_cmd="ls -ld \"${git_path}\" \"${wiki_git_path}\" \"${design_git_path}\""

  if [[ "${dry_run}" == "--dry-run=no" ]]; then
    echo "Executing command: ${cmd}"

    set -x
    eval "${cmd}"
    set +x
  else
    echo "[Dry-run] Would have executed command: ${cmd}"
    echo "[Dry-run] Instead will execute command: ${dry_run_cmd}"
    set -x
    eval "${dry_run_cmd}"
    set +x
  fi
}

function main() {
  storage_repository_delete
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

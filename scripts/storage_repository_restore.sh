#! /usr/bin/env bash

# Example usage:
#
# sudo /var/opt/gitlab/scripts/storage_repository_restore.sh --dry-run=yes '@hashed/XX/XX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
# sudo /var/opt/gitlab/scripts/storage_repository_restore.sh --dry-run=yes '@hashed/4a/68/4a68b75506effac26bc7660ffb4ff46cbb11ba00ed4795c1c5f0125f256d7f6a'
# sudo /var/opt/gitlab/scripts/storage_repository_restore.sh --dry-run=no '@hashed/4a/68/4a68b75506effac26bc7660ffb4ff46cbb11ba00ed4795c1c5f0125f256d7f6a'

EXPECTED_HASHED_STORAGE_DISK_PATH_LENGTH=78
REPOSITORIES_DIR_PATH='/var/opt/gitlab/git-data/repositories'

echo "Command-line argument parameters:"
for i in "${@}"; do echo "\"${i}\""; done

dry_run="${1}"
disk_path="${2}"

disk_path_length="${#disk_path}"
if [[ $disk_path_length -ne $EXPECTED_HASHED_STORAGE_DISK_PATH_LENGTH || $disk_path == *".."* ]]; then
  echo "Error: The given disk path seems invalid: ${disk_path}"
  exit 1
fi

dir_path=$(dirname "${REPOSITORIES_DIR_PATH}/${disk_path}")
repo_name=$(basename "${disk_path}")

moved_git_path=$(find "${dir_path}" -maxdepth 1 -name "${repo_name}+*+moved+*.git" | grep -v wiki)
if [[ ! -d "${moved_git_path}" ]]; then
  echo "Error: No moved git repository found at given disk path: \
${REPOSITORIES_DIR_PATH}/${disk_path}+*+moved+*.git"
  if [[ "${dry_run}" != "--dry-run=no" && ! -d "${REPOSITORIES_DIR_PATH}/${disk_path}.git" ]]; then
    exit 1
  fi
  echo "Warning: The repository may have already been restored"
fi

moved_wiki_git_path=$(find "${dir_path}" -maxdepth 1 -name "${repo_name}+*+moved+*.wiki.git")
if [[ ! -d "${moved_wiki_git_path}" ]]; then
  echo "Warning: No moved wiki repository found at given disk path: \
${REPOSITORIES_DIR_PATH}/${disk_path}+*+moved+*.wiki.git"
fi

original_git_path="${REPOSITORIES_DIR_PATH}/${disk_path}.git"
original_wiki_git_path="${REPOSITORIES_DIR_PATH}/${disk_path}.wiki.git"

cmd="mv \"${moved_git_path}\" \"${original_git_path}\"; \
mv \"${moved_wiki_git_path}\" \"${original_wiki_git_path}\""
dry_run_cmd="ls -ld \"${moved_git_path}\" \"${moved_wiki_git_path}\"; \
ls -ld \"${original_git_path}\" \"${original_wiki_git_path}\""

if [[ "${dry_run}" == "--dry-run=no" ]]; then
  echo "Executing command: ${cmd}"
  eval "${cmd}"
else
  echo "[Dry-run] Would have executed command: ${cmd}"
  echo "[Dry-run] Instead will execute command: ${dry_run_cmd}"
  eval "${dry_run_cmd}"
fi

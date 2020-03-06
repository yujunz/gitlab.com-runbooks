#! /usr/bin/env bash

# Example usage:
#
# sudo /var/opt/gitlab/scripts/storage_repository_info.sh '@hashed/XX/XX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
# sudo /var/opt/gitlab/scripts/storage_repository_info.sh '@hashed/4a/68/4a68b75506effac26bc7660ffb4ff46cbb11ba00ed4795c1c5f0125f256d7f6a'
# sudo /var/opt/gitlab/scripts/storage_repository_info.sh '@hashed/82/0d/820d8b182138db027b29f2ebaa5ecc57b2a9c3e9651463772d2a09cfd6773bfb'

EXPECTED_HASHED_STORAGE_DISK_PATH_LENGTH=78
REPOSITORIES_DIR_PATH='/var/opt/gitlab/git-data/repositories'

disk_path="${1}"

disk_path_length="${#disk_path}"
if [[ $disk_path_length -ne $EXPECTED_HASHED_STORAGE_DISK_PATH_LENGTH || $disk_path == *".."* ]]; then
  echo "Error: The given disk path seems invalid: ${disk_path}"
  exit 1
fi

dir_path=$(dirname "${REPOSITORIES_DIR_PATH}/${disk_path}")
repo_name=$(basename "${disk_path}")
repository_path=$(find "${dir_path}" -maxdepth 1 -name "${repo_name}*.git" | grep -v wiki)

if [[ -z "${repository_path}" ]]; then
  echo "Error: Given disk path seems invalid: ${disk_path}"
  exit 1
fi

IFS=$'\n' read -d '' -r -a commands <<"EOF"
du -hs .
du -s .
find . -maxdepth 1 -exec du -hs {} \; | sort -hr
find ./objects -maxdepth 1 -exec du -hs {} \; | sort -hr
find ./objects/pack -maxdepth 1 -exec du -hs {} \; | sort -hr
find ./refs -maxdepth 1 -exec du -hs {} \; | sort -hr
cat ./config
EOF

echo -n "cd \"${repository_path}\""
for command in "${commands[@]}"; do
  echo -n "; ${command}"
done

echo

cd "${repository_path}" || {
  echo "Error: Failure to change directory to: ${repository_path}"
  exit 1
}

for command in "${commands[@]}"; do
  eval "${command}"
done

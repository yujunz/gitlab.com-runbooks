# 
# Source this file, optionally declare the env vars that are a different
# 
local DIR=$(dirname $0)
for ENV_FILE in $(ls "${DIR}/.env"); do
  source "${DIR}/.env/${ENV_FILE}"
end

[ -z "${GITLAB_CHEF_REPO_DIR}" ] && export GITLAB_CHEF_REPO_DIR="${HOME}/Projects/gitlab/chef-repo"
[ -z "${GITLAB_COOKBOOKS_DIR}" ] && export GITLAB_COOKBOOKS_DIR="${HOME}/Projects/gitlab/cookbooks"
[ -z "${GITLAB_SSH_USER}" ]      && export GITLAB_SSH_USER="$(whoami)"
[ -z "${GITLAB_SSH_KEY}" ]       && export GITLAB_SSH_KEY="${HOME}/.ssh/id_rsa-gitlab"

source "${DIR}/bash_aliases.sh"
source "${DIR}/bash_functions.sh"

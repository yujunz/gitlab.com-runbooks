# 
# Source this file, optionally declare the env vars that are a different
# 
local DIR=$(dirname $0)
for ENV_FILE in $(ls "${DIR}/.env"); do
  source "${DIR}/.env/${ENV_FILE}"
done

[ -z "${GITLAB_CHEF_REPO_DIR}" ] && [ -d "${HOME}/Projects/gitlab/chef-repo" ] && export GITLAB_CHEF_REPO_DIR="${HOME}/Projects/gitlab/chef-repo"
[ -z "${GITLAB_COOKBOOKS_DIR}" ] && [ -d "${HOME}/Projects/gitlab/cookbooks" ] && export GITLAB_COOKBOOKS_DIR="${HOME}/Projects/gitlab/cookbooks"
[ -z "${GITLAB_SSH_KEY}" ]       && [ -f "${HOME}/.ssh/id_rsa-gitlab" ] && export GITLAB_SSH_KEY="${HOME}/.ssh/id_rsa-gitlab"
[ -z "${GITLAB_SSH_USER}" ]      && export GITLAB_SSH_USER="$(whoami)"

source "${DIR}/bash_aliases.sh"
source "${DIR}/bash_functions.sh"
source "${DIR}/dynamic_cd_path.sh"

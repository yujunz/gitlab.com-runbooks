# Purpose of this repo

This repo aims to gather all the tools we use to manage GitLab, from a simple ssh change that allows to move faster to full blown tools that make our life easier for some reason.

## Bash setup

Just source bash_gitlab.sh in your bashrc file.

Optionally, declare any of the following environment vars:
- GITLAB_CHEF_REPO_DIR
- GITLAB_COOKBOOKS_DIR
- GITLAB_SSH_USER
- GITLAB_SSH_KEY

For example:

```sh
export GITLAB_CHEF_REPO_DIR="${HOME}/Documents/Gitlab/chef-repo"
export GITLAB_COOKBOOKS_DIR="${HOME}/Documents/Gitlab/cookbooks"

source $HOME/src/gitlab.com/gl-infra/tools/bash_gitlab.sh
```

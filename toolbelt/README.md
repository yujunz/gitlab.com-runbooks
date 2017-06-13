# Purpose of this repo

This folder aims to gather all the tools we use to manage GitLab, from a simple ssh change that allows to move faster to full blown tools that make our life easier for some reason.


## Bash setup

Just source bash_gitlab.sh in your bashrc file.

Optionally, declare any of the following environment vars:
- GITLAB_CHEF_REPO_DIR
- GITLAB_COOKBOOKS_DIR
- GITLAB_SSH_USER
- GITLAB_SSH_KEY
- GITLAB_CDPATH_ROOT

For example:

```sh
export GITLAB_CHEF_REPO_DIR="${HOME}/Documents/Gitlab/chef-repo"
export GITLAB_COOKBOOKS_DIR="${HOME}/Documents/Gitlab/cookbooks"

source $HOME/src/gitlab.com/gl-infra/tools/bash_gitlab.sh
```

### Local Environment

You can create files inside the toolbelt/.env folder that will be sourced before sourcing the rest of the files.

Use this to add any function or environment varilable that is needed by the rest of the scripts.

### Dynamic CD PATH

To enable dynamic generation of CDPATH export the GITLAB_CDPATH_ROOT array variable before sourcing
the toolbelt

Ex:
 export GITLAB_CDPATH_ROOT=("${HOME}/src/gitlab.com" "${HOME}/src/dev.gitlab.org")

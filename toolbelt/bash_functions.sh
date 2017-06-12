# GitLab

# Requires definitions
# GITLAB_CHEF_REPO_DIR
# GITLAB_COOKBOOKS_DIR
# GITLAB_SSH_USER
# GITLAB_SSH_KEY

[ -z "${GITLAB_CHEF_REPO_DIR}" ] && echo "GITLAB_CHEF_REPO_DIR is not defined" && return 1
[ -z "${GITLAB_COOKBOOKS_DIR}" ] && echo "GITLAB_COOKBOOKS_DIR is not defined" && return 1
[ -z "${GITLAB_SSH_USER}" ] && echo "GITLAB_SSH_USER is not defined" && return 1
[ -z "${GITLAB_SSH_KEY}" ] && echo "GITLAB_SSH_KEY is not defined" && return 1

## Chef

function cookbook {
  if [[ $1 == 'ls' ]]; then
    ls -1 $GITLAB_COOKBOOKS_DIR
  else
    cd ${GITLAB_COOKBOOKS_DIR}/$1 || echo 'Invalid cookbook'
  fi
}

function gitlab-nodes {
  pushd . >/dev/null
  cd ${GITLAB_CHEF_REPO_DIR} || return 1
  knife node list
  popd >/dev/null
}

function gip {
  [ -z $1 ] && echo "No hostname provided" && return 1
  pushd . >/dev/null
  cd ${GITLAB_CHEF_REPO_DIR} || return
  knife node show $1 | awk '/^IP/{print $2}'
  popd >/dev/null
}

function gssh {
  ip=$1
  shift
  [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || ip=$(gip $ip)
  [ -z $ip ] && echo "Invalid ip or hostname" && return 1
  ssh -i ${GITLAB_SSH_KEY} ${GITLAB_SSH_USER}@$ip $@
}

function ghaproxy-stats-tunnel {
  [ -z $1 ] && echo "No hostname provided" && return 1
  gssh $1 -nNTL 7331:127.0.0.1:7331 -p 2222
}

function gitlab-nodes-with-ips {
  pushd . >/dev/null
  cd ${GITLAB_CHEF_REPO_DIR} || return
  for node in $(knife node list); do 
    ip=$(knife node show $node | grep "IP:" | sed -e 's/IP: *//')
    echo $ip - $node
  done
  popd >/dev/null
}

function rm_merged_branches {
  if [[ ! -d .git ]]; then
    echo "Not a git repo" 
    return 1
  fi
  for branch in `git branch --merged | grep -v master`
  do 
    git branch -d $branch
  done
  echo "Done"
}

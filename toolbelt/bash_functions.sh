# GitLab

# Requires definitions
# GITLAB_CHEF_REPO_DIR
# GITLAB_COOKBOOKS_DIR
# GITLAB_SSH_USER
# GITLAB_SSH_KEY

## Terraform
function gitlab-terraform {
  case $1 in
    staging)
      export CONSUL_HTTP_ADDR=""
      export CONSUL_HTTP_TOKEN=""
      export TF_VAR_arm_subscription_id=""
      export TF_VAR_arm_tenant_id=""
      export TF_VAR_arm_client_id=""
      export TF_VAR_arm_client_secret=""
      export TF_VAR_first_user_username=""
      export TF_VAR_first_user_password=""
      ;;
    environments)
      export CONSUL_HTTP_ADDR=""
      export CONSUL_HTTP_TOKEN=""
      export TF_VAR_do_dev_token=""
      ;;
    disable)
      unset CONSUL_HTTP_ADDR \
            CONSUL_HTTP_TOKEN \
            TF_VAR_arm_subscription_id \
            TF_VAR_arm_tenant_id \
            TF_VAR_arm_client_id \
            TF_VAR_arm_client_secret \
            TF_VAR_first_user_username \
            TF_VAR_first_user_password
      ;;
    *) echo "Usage: gitlab-terraform <staging|environments|disable>"
      ;;
  esac
}

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
  cd ${GITLAB_CHEF_REPO_DIR} || return
  knife node list
  popd >/dev/null
}

function gip {
  [ -z $1 ] && echo "No hostname provided" && return
  pushd . >/dev/null
  cd ${GITLAB_CHEF_REPO_DIR} || return
  knife node show $1 | awk '/^IP/{print $2}'
  popd >/dev/null
}

function gssh {
  ip=$1
  shift
  [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || ip=$(gip $ip)
  [ -z $ip ] && echo "Invalid ip or hostname" && return
  ssh -i ${GITLAB_SSH_KEY} ${GITLAB_SSH_USER}@$ip $@
}

function ghaproxy-stats-tunnel {
  [ -z $1 ] && echo "No hostname provided" && return
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
    return
  fi
  for branch in `git branch --merged | grep -v master`
  do 
    git branch -d $branch
  done
  echo "Done"
}

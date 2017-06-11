# GitLab Aliases
alias   knife="bundle exec knife"
alias    rake="bundle exec rake"
alias kitchen="bundle exec kitchen"
alias   berks="bundle exec berks"
[ -z "$GITLAB_SSH_KEY" ] && alias kssh="knife ssh -i $GITLAB_SSH_KEY"

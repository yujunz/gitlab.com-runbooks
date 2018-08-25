# Git

## Test pushing through all the git nodes

This is particularly useful to understand if a particular git node is misbehaving

### Steps

1. Ensure that you have a test repo in your GitLab account you can push to.
1.  Use this script

```
for i in $(seq -w 1 12);do
  echo -n pushing via git-$i:
  touch git-${i}
  git add -A
  git commit -m "push via git-$i" >/dev/null
  GIT_SSH_COMMAND="ssh -o LogLevel=error" git push ssh://git@git-${i}.sv.prd.gitlab.com/${USER}/test-repo.git >/dev/null 2>/dev/null
  echo $?
done
```

### Result

This script returns the return code from git for each git node. A `0` means
that things went fine, any other code is the specific git output code.

## Check transport problems

You can increase git verbosity by defining environment variables, for example:

```
GIT_SSH_COMMAND="ssh -v" git pull
```

This command will increase ssh verbosity to help troubleshooting a connection
problem.

## Disable Chef runs on a VM

Occasionally there will be a legitimate reason to stop Chef on a Chef managed
GitLab VM. You should follow the following steps to ensure that it both
communicates the reason for stopping Chef and prevents someone else from
starting the chef-client service when it is intentionally disabled.

**Stopping Chef should never ben done unless it is absolutely needed and should
never be stopped for more than 12 hours without a corresponding issue**

For reference, the current procedure uses scripts provided by Chef recipe
[gitlab-server::chef-client-disabler](https://gitlab.com/gitlab-cookbooks/gitlab-server/-/blob/master/recipes/chef-client-disabler.rb).
Its main purpose is to intercept calls to `chef-client` and put the contextual
information (when, by whom, and why chef-client was disabled) directly in the path
of the hapless user who is trying to run chef-client as part of an unrelated change.

### Disable Chef runs

The disable script takes an optional comment.  Please use it to describe
why chef is being disabled, and include an issue link if available.

```shell
$ chef-client-disable 'Manual edits to foo.conf, see issue https://gitlab.com/gitlab-com/gl-infra/production/-/issues/1878'
```

### Enable Chef runs

```shell
$ chef-client-enable
```

### Historical procedure

The old procedure stops periodic chef-client runs and then
breaks chef-client by moving aside the directory containing
chef-client's credentials and config.

The new procedure is simply to run a script that intercepts
calls to chef-client and gives the caller contextual info,
including any message left by the person who disabled
chef-client (e.g. issue link, what has been locally modified,
etc.).  It also stops the periodic runs of chef-client.

The old procedure (shown below) still works, but it is
incompatible with the new procedure.  (Please do not disable
with one procedure and then try to enable with the other.)

```shell
# Stop periodic runs, and then cripple chef-client by hiding its credentials/config dir.

$ sudo service chef-client stop

# Examples: mv /etc/chef /etc/chef.disabled.because.of.pg.conf.override
#           mv /etc/chef /etc/chef.infra-1231

$ sudo mv /etc/chef /etc/chef.{reason}

# Later, re-enable chef by restoring its credentials dir and restarting periodic runs.

$ sudo mv /etc/chef.{reason} /etc/chef
$ sudo service chef-client start
```

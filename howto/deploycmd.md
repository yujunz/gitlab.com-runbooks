# Deploy Cmd for Chatops

The purpose of this command in Chatops is to run pre-vetted, common commands
across the Gitlab.com fleet in a repeatable, and convenient way. The commands
are defined in ansible playbooks. When a command is run, it will execute on
10% of the role nodes at a time, with a minimum of 1 node per step. If the
nodes are in haproxy, by default the node will be gracefully removed from
taking traffic, the command applied, then set to resume taking traffic.

There are options to control the environment the command is run in, if haproxy
steps are to be skipped, and to disable dry-run mode.

## Deploy Tooling Commands

The root of this command system are a [playbook](https://ops.gitlab.net/gitlab-com/gl-infra/deploy-tooling/blob/master/cmd.yml)
that can execute a simple command playbook from the [cmds](https://ops.gitlab.net/gitlab-com/gl-infra/deploy-tooling/tree/master/cmds)
directory of the [deploy-tooling](https://ops.gitlab.net/gitlab-com/gl-infra/deploy-tooling)
project. The `CMD` variable is used to determine which playbook in the cmds
directory will be run.

[cmds readme](https://ops.gitlab.net/gitlab-com/gl-infra/deploy-tooling/blob/master/cmds/README.md)
provides information on how to test and add new commands.

## Deployer Pipelines

The deploy-tooling project is a sub-repository for the [deployer](https://ops.gitlab.net/gitlab-com/gl-infra/deployer)
project. The deployer CI process is used to run the ansible playbooks contained
inside the deploy-tooling project. If a `CURRENT_DEPLOY_ENVIRONMENT`,
`CMD`, and `GITLAB_ROLE` variable are each specified, the CI process will
attempt to run the `cmd.yml` playbook and specified command.

If needed, a command can be executed by [running the CI pipeline](https://ops.gitlab.net/gitlab-com/gl-infra/deployer/pipelines/new)
and specifying the required variables. If you want to make sure it runs and
does not use `--check` mode, specify the variable `CHECKCOMMAND` to be `false`.

## Chatops Command

The Chatops bot can list the ansible playbooks available to run in the
[deploy-tooling project](https://ops.gitlab.net/gitlab-com/gl-infra/deploy-tooling).

An example on how to run the `hostname` command on the `base-fe-we-pages` chef
role systems in staging:
```
/chatops run deploycmd hostname base-fe-web-pages --skip-haproxy
```
This will run the `hostname` command on the staging nodes with the role
`base-fe-web-pages` and skip any haproxy steps. This specific command will be
a dry-run with no changes made.

Another example:
```
/chatops run deploycmd hostname base-fe-web-pages --no-check --production
```
This command will run hostname on the `base-fe-web-pages` nodes in production
and not skip the graceful haproxy removal and re-addition steps. The
`--no-check` flag will allow this command to actually make changes.

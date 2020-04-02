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
and specifying the required variables. A dry-run can be specified by
specifying the variable `CHECKCOMMAND` as `true`. If this is not done, the
ansible script will make changes.

## Chatops Command

The Chatops bot can list the ansible playbooks available to run in the
[deploy-tooling project](https://ops.gitlab.net/gitlab-com/gl-infra/deploy-tooling).

The general form of the command is:
```
/chatops run deploycmd CMD_NAME BASE_ROLE_NAME [--ENVIRONMENT] [--skip-haproxy] [--no-check]
```

where 
* CMD_NAME is a file from https://ops.gitlab.net/gitlab-com/gl-infra/deploy-tooling/-/tree/master/cmds
    (without the .yml extension)
* BASE_ROLE_NAME is the name of the chef role to operate on *without* the 
    environment prefix, and with underscores replacing hyphens, e.g. base_fe_git
* ENVIRONMENT is optional, defaulting to staging.  You can choose from
    production, dr, canary, or pre, e.g. `--production`
* If --skip-haproxy is included, do *not* drain/add nodes from haproxy around
    running the command.  Otherwise the drain/add will occur
* --no-check is required to actually run commands; without this, ansible will
     operate in `dry-run` mode and take no active/destructive actions

### Examples:
To run the `hostname` command on the `base-fe-we-pages` chef role systems in staging:
```
/chatops run deploycmd hostname base_fe_web_pages --skip-haproxy
```
This will run the `hostname` command on the staging nodes with the role
`base-fe-web-pages` and skip the haproxy drain/add. This specific command will be
a dry-run with no changes made.

This command will run hostname on the `base-fe-web-pages` nodes in production
and will do the graceful haproxy removal and re-addition. The
`--no-check` flag will allow this command to actually make changes.
```
/chatops run deploycmd hostname base_fe_web_pages --no-check --production
```


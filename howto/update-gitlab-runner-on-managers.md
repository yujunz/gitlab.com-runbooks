# Update GitLab Runner on runners managers

This runbook describes procedure of upgrading GitLab Runner on our runner managers.

## Roles to runners mapping

- `gitlab-private-runners`
    - private-runners-manager-1.gitlab.com
    - private-runners-manager-2.gitlab.com
- `gitlab-shared-runners`
    - shared-runners-manager-1.gitlab.com
    - shared-runners-manager-2.gitlab.com
- `gitlab-gce-shared-runners-east-d`
    - shared-runners-manager-3.gitlab.com
- `gitlab-gce-shared-runners-east-c`
    - shared-runners-manager-4.gitlab.com
- `gitlab-ce-ee-runners`
    - gitlab-shared-runners-manager-1.gitlab.com
    - gitlab-shared-runners-manager-2.gitlab.com
- `gitlab-gce-ce-ee-runners-east-d`
    - gitlab-shared-runners-manager-3.gitlab.com
- `gitlab-gce-ce-ee-runners-east-c`
    - gitlab-shared-runners-manager-4.gitlab.com
- `omnibus-builder-runners-manager`
    - omnibus-builder-runners-manager.gitlab.org
- `gitlab-runner-builder`
    - gitlab-runner-builder.gitlap.com

## Requirements

To upgrade runners on managers you need to:

- have write access to dev.gitlab.org/cookbooks/chef-repo,
- have write access to chef.gitlab.com,
- have configured knife environment,
- have admin access to nodes (sudo access).

## Procedure description

> **Notice**: to make update process transparent for users we should update one runner's host
> at a time. For example GitLab CE project on GitLab.com is using four runners: gitlab-shared-runners-manager-1,
> gitlab-shared-runners-manager-2 (as a shared runners), and both private-runners-manager-X (as specific runners).
>
> If we want to update private-runners-manager-X we should first update private-runners-manager-1, and after this
> update the private-runners-manager-2. It needs to be done like this because of Runner's graceful stop process -
> Runner needs time to finish running builds and during this time it will not handle new builds.
>
> Because of this updating all Runners at once could block jobs processing even for two hours!

1. **Shutdown `chef-client` process on managers being updated**

    For example, to shutdown chef-client on private-runners-manager-X.gitlab.com, you can execute:

    ```bash
    $ knife ssh -aipaddress 'roles:gitlab-private-runners' -- sudo service chef-client stop
    ```

    To be sure that chef-cilent process is terminated you can execute:

    ```bash
    $ knife ssh -aipaddress 'roles:gitlab-private-runners' -- "service chef-client status; ps aux | grep chef"
    ```

1. **Update chef role (or roles)**

    > **Notice:** This needs to be done only onece if you are updating few nodes using the same role.

    In `chef-repo` directory execute:

    ```bash
    $ rake edit_role[gitlab-private-runners]
    ```

    where `gitlab-private-runners` is a role used by nodes that you are updating. Please check the
    [roles to runners mapping section](#roles-to-runners-mapping) to find which role you're interested in.

    For omnibus-builder-runers-manager.gitlab.com you should edit `omnibus-builder-runners-manager` role's secrets:

    ```bash
    $ rake edit_role_secrets[omnibus-builder-runners-manager,_default]
    ```

    In attributes list look for `cookbook-gitlab-runner:gitlab-runner:version` and change it to a version that you want
    to update. It should look like:

    ```json
    "cookbook-gitlab-runner": {
      "chef-vault" : "gitlab-private-runners",
      "gitlab-runner": {
        "repository": "gitlab-ci-multi-runner",
        "version": "9.3.0"
      }
    }
    ```

    If you want to install a Bleeding Edge version of the Runner, you should set the `repository`
    value to `unstable`.

    If you want to install a Stable version of the Runner, you should set the `repository` value to
    `gitlab-ci-multi-runner` (which is a default if the key doesn't exists in configuration).

1. **Upgrade all GitLab Runners**

    To upgrade chosen Runners manager, execute the command:

    ```bash
    $ knife ssh -C1 -aipaddress 'roles:gitlab-private-runners' -- sudo /root/runner_upgrade.sh
    ```

    This will send a stop signal to the Runner. The process will wait until all handled jobs are finished,
    but no longer than 7200 seconds. The `-C1` flag will make sure that only one node using chosed role
    will be updated at a time.

    While waiting for jobs to be finished you can check what jobs in which state are running - open
    another console window, log into chosen Runner and execute the following command:

    ```bash
    $ ssh private-runners-manager-1
    user@private-runners-manager-1:~$ curl -s http://localhost:9402/debug/jobs/list
    ```

    When the last job will be finished, or after the 7200 seconds timeout, the process will
    be terminated and the script will:
    - remove all Docker Machines that were created by Runner
      (using the `/root/machines_operations.sh remove-all` script),
    - upgrade Runner and configuration with `chef-client` (which will also start the `chef-client` process
      stopped in the first step of the upgrade process),
    - start Runner's process and check if process is running,
    - show the output of `gitlab-runner --version`.

    When upgrade of the first Runner is done, then continue with another one.

1. **Verify the version of GitLab Runner**

    If you want to check which version of Runner is installed, execute the following command:

    ```bash
    $ knife ssh -aipaddress 'roles:gitlab-private-runners' -- gitlab-runner --version
    ```

    You can also check the [uptime](https://performance.gitlab.net/dashboard/db/ci?refresh=5m&orgId=1&panelId=18&fullscreen)
    and [version](https://performance.gitlab.net/dashboard/db/ci?refresh=5m&orgId=1&panelId=12&fullscreen) on
    CI dashboard at https://performance.gitlab.net/. Notice that the version table shows versions existing for last 1
    minute so if you check it immediately after upgrading Runner you may see it twice - with old and new version.
    After a minute the old entry should disappear.

1. **Update GitLab.com's configuration description**

    If you are updating shared runners used by GitLab.com, please create a merge request in
    https://gitlab.com/gitlab-com/www-gitlab-com project to update Runner's version and/or any other changed
    configuration values which are specified at
    https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/source/gitlab-com/settings/index.html.md#shared-runners.

## Upgrade of whole GitLab.com Runners fleet

If you want to upgrade all Runners of GitLab.com fleet at the same time, then you can use the following script:

```bash
# Stop chef-client
knife ssh -aipaddress 'roles:gitlab-private-runners OR roles:gitlab-shared-runners OR roles:gitlab-ce-ee-runners OR roles:gitlab-gce-*-runners-* OR roles:omnibus-builder-runners-manager OR roles:gitlab-runner-builder' -- sudo service chef-client stop

# Update configuration in roles definition and secrets
rake edit_role[gitlab-private-runners]
rake edit_role_secrets[gitlab-private-runners,_default]
rake edit_role[gitlab-shared-runners]
rake edit_role_secrets[gitlab-shared-runners,_default]
rake edit_role[gitlab-ce-ee-runners]
rake edit_role_secrets[gitlab-ce-ee-runners,_default]
rake edit_role[gitlab-gce-shared-runners-east-d]
rake edit_role_secrets[gitlab-gce-shared-runners-east-d,_default]
rake edit_role[gitlab-gce-shared-runners-east-c]
rake edit_role_secrets[gitlab-gce-shared-runners-east-c,_default]
rake edit_role[gitlab-gce-ce-ee-runners-east-d]
rake edit_role_secrets[gitlab-gce-ce-ee-runners-east-d,_default]
rake edit_role[gitlab-gce-ce-ee-runners-east-c]
rake edit_role_secrets[gitlab-gce-ce-ee-runners-east-c,_default]
rake edit_role[omnibus-builder-runners-manager]
rake edit_role_secrets[omnibus-builder-runners-manager,_default]
rake edit_role[gitlab-runner-builder]
rake edit_role_secrets[gitlab-runner-builder,_default]

# Upgrade Runner's version and configuration on nodes
knife ssh -C1 -aipaddress roles:gitlab-private-runners -- sudo /root/runner_upgrade.sh &
knife ssh -C1 -aipaddress roles:gitlab-shared-runners -- sudo /root/runner_upgrade.sh &
knife ssh -C1 -aipaddress roles:gitlab-ce-ee-runners -- sudo /root/runner_upgrade.sh &
knife ssh -C1 -aipaddress roles:gitlab-gce-shared-runners-east-d -- sudo /root/runner_upgrade.sh &
knife ssh -C1 -aipaddress roles:gitlab-gce-shared-runners-east-c -- sudo /root/runner_upgrade.sh &
knife ssh -C1 -aipaddress roles:gitlab-gce-ce-ee-runners-east-d -- sudo /root/runner_upgrade.sh &
knife ssh -C1 -aipaddress roles:gitlab-gce-ce-ee-runners-east-c -- sudo /root/runner_upgrade.sh &
knife ssh -C1 -aipaddress roles:omnibus-builder-runners-manager -- sudo /root/runner_upgrade.sh &
knife ssh -C1 -aipaddress roles:gitlab-runner-builder -- sudo /root/runner_upgrade.sh &
wait
```

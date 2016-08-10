# Update GitLab Runner on runners managers

This runbook describes procedure of upgrading GitLab Runner on our runner managers:

- docker-ci-1.gitlap.com
- docker-ci-2.gitlap.com
- shared-runners-manager-1.gitlab.com
- shared-runners-manager-2.gitlab.com
- omnibus-builder-runners-manager.gitlab.org

## Requirements

To upgrade runners on managers you need to:

- have write access to dev.gitlab.org/cookbooks/chef-repo,
- have write access to chef.gitlab.com,
- have configured knife environment,
- have admin access to nodes (sudo access),
- have admin access to GitLab each instance connected with updated runner (for updating shared runners) **OR**
- have master access to at least one project connected with a specific runner on each GitLab instance
  where runner is used.

## Procedure

> **Notice**: to make update process transparent for users we should update one runner's host
> at a time. For example GitLab CE project on GitLab.com is using four runners: both shared-runners-manager-X
> (as a shared runners), and both docker-ci-X (as specific runners).
>
> If we want to update docker-ci-X we should first update docker-ci-1, and after this update the docker-ci-2.
> It needs to be done like this because of pausing runner - for a time needed to finish running builds the
> runner will not handle new builds.

1. **Shutdown `chef-client` process on managers beeing updated**

    For example, to shutdown chef-client on docker-ci-X.gitlap.com, you can execute:

    ```bash
    $ knife ssh -aipaddress 'role:gitlab-private-runners' -- sudo service chef-client stop
    ```

    To be sure that chef-cilent process is terminated you can execute:

    ```bash
    $ knife ssh -aipaddress 'role:gitlab-private-runners' -- "service chef-client status; ps aux | grep chef"
    ```

1. **Update chef role (or roles)**

    > **Notice:** This needs to be done only onece if you are updating few nodes using the same role.

    While waiting for process to be terminated we can update role (or roles) configuration to set a new
    version of a runner.

    In `chef-repo` directory execute:

    ```bash
    $ rake edit_role[gitlab-private-runners]
    ```

    where `gitlab-private-runners` is a role used by nodes that you are updating. It will be `gitlab-private-runners`
    for docker-ci-X.gitlap.com or `gitlab-shared-runners` for shared-runners-manager-X.gitlab.com.

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
        "repository": "unstable",
        "version": "1.4.0~beta.77.g0ac09d5"
      }
    }
    ```

    If you want to install a Bleeding Edge version of the Runner, you should set the `repository` value to `unstable`.
    If you want to install a Stable version of the Runner, you should set the `repository` value to
    `gitlab-ci-multi-runner` (which is a default if the key doesn't exists in configuration).

1. **Shutdown GitLab Runner service**

    SSH to the host - e.g. `$ ssh docker-ci-1.gitlap.com` and paste this in terminal

        ```bash
        echo manual | sudo tee /etc/init/gitlab-runner.override
        sudo killall -SIGQUIT gitlab-ci-multi-runner
        while gitlab-runner status; do sleep 1s; done
        ```

    The above script disables auto start of service after its exit. We are sending SIGQUIT to signal a Runner that it should not process a new builds, but finish existing ones and exit. You will have to wait till this script finishes, but when it finished it means that Runner did finish processing of all builds and you are free to start a chef client.

1. **Start `chef-client` process on a node**

    If old process finished all builds (and was restarted by upstart) you can restart `chef-client` on the node.

    ```bash
    $ sudo service chef-client start
    ```

    Now remove the manual override for process startup:

    ```bash
    $ sudo rm /etc/init/gitlab-runner.override
    ```

    You can check if the process is runing by:

    ```bash
    $ service chef-client status; ps aux | grep chef-client
    ```

    Chef-client in next half of hour should update all configuration. After this time you can check if the runner
    was updated:

    ```bash
    $ gitlab-runner --version
    Version:      1.4.0~beta.77.g0ac09d5
    Git revision: 0ac09d5
    Git branch:   master
    GO version:   go1.6.3
    Built:        Wed, 20 Jul 2016 14:44:37 +0000
    OS/Arch:      linux/amd64
    ```

    If you don't want to wait for chef-client process to update configuration, you can run chef-client by hand
    **after you've started the process**, by executing:

    ```bash
    $ sudo chef-client
    ```

1. **Repeat procedure for other nodes**

    If you are updating few nodes (e.g. docker-ci-X.gitlap.com) you should repeat points 3., 4. for each
    next node. There is no need to repeat 1. (you've stopped `chef-client` process on all nodes at once) and no need
    to repeat 4. (you need to update role configuration only once).

## TL;DR

    You can do all of that much faster:

    1. Stop Chef Client as in **1.**:

    ```
    # For docker-ci-X.gitlap.com
    $ knife ssh -aipaddress 'role:gitlab-private-runners' -- sudo service chef-client stop

    # For shared-runners-manager-X.gitlab.com
    $ knife ssh -aipaddress 'role:gitlab-shared-runners' -- sudo service chef-client stop

    # For Omnibus builders
    $ knife ssh -aipaddress 'role:omnibus-builder-runners-manager' -- sudo service chef-client stop
    ```

    2. Update Chef Cookbooks as in **2.**

    ```bash
    # For docker-ci-X.gitlap.com
    $ rake edit_role[gitlab-private-runners]

    # For shared-runners-manager-X.gitlab.com
    $ rake edit_role[gitlab-shared-runners]

    # For Omnibus builders
    $ rake edit_role_secrets[omnibus-builder-runners-manager,_default]
    ```

    3. Execute this on each node:

    ```
    cat <<EOF | ssh myusername@shared-runners-manager-1.gitlab.com

    echo Disabling GitLab Runner autostart...
    echo manual | sudo tee /etc/init/gitlab-runner.override

    echo Signal stop of build processing...
    sudo killall -SIGQUIT gitlab-ci-multi-runner

    echo Waiting for GitLab Runner to finish...
    while gitlab-runner status; do sleep 1s; done

    echo Starting chef-client...
    sudo service chef-client start

    echo Waiting for GitLab Runner to start
    while ! gitlab-runner status; do sleep 1s; done

    echo Enabling autostart...
    sudo rm /etc/init/gitlab-runner.override

    echo Verify the new version...
    gitlab-runner --version
    ```


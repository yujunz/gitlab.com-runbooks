# CI runnner manager report a high number of errors

## Possible checks

1. Check DigitalOcean status on Twitter: [@DOStatus](https://twitter.com/DOStatus). Have an eye on this site
   until the problem is resolved.

1. SSH into the machine having issues. For example:

    ```bash
    $ ssh shared-runners-manager-1.gitlab.com
    ```

1. Check the status of machines:

    ```bash
    $ sudo su
    # /root/machines_operations.sh list
    # /root/machines_operations.sh count
    ```

1. Check logs in `/var/log/upstart/gitlab-runner.log`.

## Resolution

1. If number of machines in `FAILING` state is higher than normal - remove them.
   For this fallow [this runbook](./ci_runner_manager_errors.md#resolution)

1. If the problem needs to be handled by DigitalOcean consider to pause the runners:

    > **Notice:**
    > You will need GitLab Admin access for this!

    * go to https://gitlab.com/admin/runners page (for `docker-ci-[1-2].gitlap.com` also to
        https://dev.gitlab.org/admin/runners)
    * entery runner's description (eg. `docker-ci-1.gitlap.com`) in _Runner description or token_ field
      and press `Search` button
    * press `Pause` button for a selected runner

    To unpause the runner repeat above steps and use a `Resume` button in the last one.

## Post checks

1. Check the status of machines:

    ```bash
    $ sudo su
    # /root/machines_operations.sh list
    # /root/machines_operations.sh count
    ```

    Number of machines in `FAILING` state should be less than 20-30.

1. Check MK - `DO_TOKEN_RATE_LIMITS` service should be back to normal

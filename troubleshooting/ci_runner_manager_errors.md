# CI runner manager report a high number of errors

## Possible checks

1. Check DigitalOcean status on Twitter: [@DOStatus](https://twitter.com/DOStatus).

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

1. You can also do a check using Docker Machine:

    > **Notice:**
    > `docker-machine ls` is doing an API call for each machine configured on the host. This will increase the
    > DigitalOcean Token Rate Limits usage. Please use this command carefully and consider to skip this step if
    > `DO_TOKEN_RATE_LIMITS` service for this host in Check MK is also _WARNING_ or _CRITICAL_.

    ```bash
    $ sudo su
    # docker-machine ls
    ```

    Save this output for later troubleshooting.

1. Check logs in `/var/log/upstart/gitlab-runner.log`.

## Resolution

1. Remove the failing machines via the `machines_operations.sh` script:

    > **Notice:**
    > Below command can also remove machines that were created recently and didn't received
    > a `DropletID` value yet. We should update the script to remove only machines marked as
    > `FAILING` which are created more than 2 minutes ago (or less/more?).

    ```bash
    $ sudo su
    # /root/machines_operations.sh remove-failing
    ```

1. Do a cross-check of machines on DigitalOcean and remove machines that are no longer managed
   by the host.

    > **Notice:**
    > We need a script for this!

## Post checks

1. Check the status of machines:

    ```bash
    $ sudo su
    # /root/machines_operations.sh list
    # /root/machines_operations.sh count
    ```

    Number of machines in `FAILING` state should be less than 20-30.

1. Check MK - `Docker_machine` service should be back to normal

# CI runnner machines report a high number of errors

## Symptoms

* Check MK links
    1. [shared-runners-manager-1.gitlab.com](https://checkmk.gitlap.com/gitlab/check_mk/index.py?start_url=%2Fgitlab%2Fpnp4nagios%2Findex.php%2Fgraph%3F%26host%3Dshared-runners-manager-1.gitlab.com%26srv%3DDocker_machine%26source%3D1%26theme%3Dmultisite%26baseurl%3D%2Fgitlab%2Fcheck_mk%2F)
    2. [shared-runners-manager-2.gitlab.com](https://checkmk.gitlap.com/gitlab/check_mk/index.py?start_url=%2Fgitlab%2Fpnp4nagios%2Findex.php%2Fgraph%3F%26host%3Dshared-runners-manager-2.gitlab.com%26srv%3DDocker_machine%26source%3D0%26theme%3Dmultisite%26baseurl%3D%2Fgitlab%2Fcheck_mk%2F)
* ![Sample High Errors on runner machines](img/ci-runner-manager-errors.png)

## Possible checks

1. SSH into the machine having issues. For example:

    ```sh
    ssh shared-runners-manager-1.gitlab.com
    ```

1. Check the status of docker-machine:

    ```sh
    $ sudo su
    $ docker-machine ls
    ```

    Save this output for later troubleshooting.

1. Check logs in `/var/log/upstart/gitlab-runner.log`.

## Resolution

1. Remove the failing machines via the `machines_operations.sh` script:

    ```sh
    $ sudo su
    $ /root/machines_operations.sh remove-failing
    ```

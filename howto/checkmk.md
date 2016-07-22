# Check MK

CheckMK is the main systems level monitoring tool that we use to check the health of the cluster.

## Relevant information

Where: https://checkmk.gitlap.com
How to login: use OAuth to login with a @gitlab.com account
To ssh into the host go use `ssh checkmk.gitlap.com`

This host is controlled by chef and has the `gitlab-checkmk-server` role applied.

Every host that is monitored by checkmk has the `gitlab-checkmk-client` applied.


## Overview

Check_MK can be a bit overwhelming when you look at it first time, you actually only need to focus on the unhandled problems:
- [Click in the upper left conner (Tactical Overview box) on the `Unhandled` link](https://checkmk.gitlap.com/gitlab/check_mk/index.py?start_url=%2Fgitlab%2Fcheck_mk%2Fview.py%3Fview_name%3Dsvcproblems%26is_service_acknowledged%3D0)

If you want to see all problems even the handled ones (a handled problem is an acknowledged problem):
- [Click in the upper left conner (Tactical Overview box) on the `Problems` link](https://checkmk.gitlap.com/gitlab/check_mk/index.py?start_url=%2Fgitlab%2Fcheck_mk%2Fview.py%3Fview_name%3Dsvcproblems)

## Service problems

There are two types of service problems namely handled and unhandled.
Unhandled service problems are bad! It means that nobody is working on this service problem.

### Handle unhandled service problems:
- Create a new issue for it at: https://gitlab.com/gitlab-com/infrastructure/issues/new
- Acknowledge this problem with the issue link as comment:
    - Click on the service link
    - Click on the hammer icon
    - Fill in the Acknowledge box (most top box) the comment field with the link to the issue and click on the acknowledge button. 


## Managing users

Users are automatically created by Check_MK based on OAuth with role Administrator.

## Plugins

CheckMK supports adding plugins both official and home cooked

### Official plugins

We use chef to manage which official plugins are activated, to find a sample you can check
(how we enable the postgres plugin)[https://dev.gitlab.org/cookbooks/gitlab-checkmk/blob/master/recipes/plugin-postgres.rb]
in our checkmk cookbook.

A list of the available plugins can be found here: http://mathias-kettner.com/checkmk_check_catalogue.html


### Home baked plugins

To create a plugin we need to add a script file in the host that we want to monitor in the path `/usr/lib/check_mk_agent/local/`

A sample of a script looks like this:

```
#!/bin/bash
docker=$(echo /root/.docker/machine/machines/* | wc -w)
echo "0 Docker_machine dockers=$docker;;;0; OK - $docker docker machines running"
```

This one in particular is used to push the number of docker instances that are being managed by a runner.

More information: https://mathias-kettner.de/checkmk_localchecks.html

### Creating a plugin

Consider creating a chef recipe so we can reuse it easily, just add a new recipe file to the checkmk cookbook and apply it
to the host that we want to monitor.

## Updating the metrics for a whole chef role

There is a new rake task for updating the metrics for a whole chef role, it goes like this:

```
rake update_checkmk[role-to-update]
```

This will handle SSH-ing into the checkmk server and updating the checks.

## Troubleshooting

- UNKNOWN - Check output not found in local checks

    Existing agent data is out of sync for that host, do a re-inventory of that host and reload Check_MK:
    
    ```sudo su - gitlab; cmk -II <hostname> && cmk -O```

- UNKNOWN - Database not found

    Existing agent data is out of sync for that host, do a re-inventory of that host and reload Check_MK:
    
    ```sudo su - gitlab; cmk -II <hostname> && cmk -O```


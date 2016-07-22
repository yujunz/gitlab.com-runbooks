# Check MK

CheckMK is the main systems level monitoring tool that we use to check the health of the cluster.

## Relevant information

Where: https://checkmk.gitlap.com
How to login: use OAuth to login with a @gitlab.com account
To ssh into the host go use `ssh checkmk.gitlap.com`

This host is controlled by chef and has the `gitlab-checkmk-server` role applied.

Every host that is monitored by checkmk has the `gitlab-checkmk-client` applied.


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

From time to time it can happen that checkmk looses track of the host it is tracking, this can be shown with an
error message like `UNKNOWN - Database not found`

To force checkmk to update and reload the configuration you will need to issue this command:
`sudo su - gitlab; cmk -II db5.cluster.gitlab.com && cmk -O`

Where db5.cluster.gitlab.com is the host we want to reload.


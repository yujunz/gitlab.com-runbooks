# Blocking and disabling things in the HAProxy load balancers

## First and foremost

* *Don't Panic*
* But test things in a local LB

## Background

HAPRoxy is the main load balancer we use, it is configured first in the
[NFS cluster cookbook](https://dev.gitlab.org/cookbooks/gitlab-nfs-cluster/blob/master/templates/default/haproxy.cfg.erb)
and then there an [lb role in the chef repo](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/roles/gitlab-cluster-lb.json)

## How do I

### Apply a quick configuration?

To apply a quick configuration to the load balancers the way to go is to change the haproxy custom
configuration in the chef repo.
to do so you will need to issue the command `bundle exec rake "edit_role[gitlab-base-lb]"` from the
chef-repo folder with knife properly configured.

The value to change is "https_custom_config", be careful to respect spaces and to keep previous values:
``` json
  "override_attributes": {
    "gitlab-nfs-cluster": {
      "haproxy": {
        "chef_vault": "gitlab-base-lb",
        "server_timeout": "1h",
        "https_custom_config": "  acl mash2k3_uri path_beg -i /mash2k3/mash2k3-repository/raw/\n  http-request deny if mash2k3_uri\n"
      }
    }
```

#### Samples of configurations:

##### Deny a path with the DELETE http method

```
acl is_stop_impersonation  path_beg         /admin/users/stop_impersonation
acl is_delete method DELETE
http-request deny if is_delete is_stop_impersonation
```

#### Once the changes are applied

Remember to run the chef-client in all the LBs
`knife ssh -p 2222 -C 1 -a ipaddress role:gitlab-base-lb  'sudo chef-client'`

Note the port 2222 for ssh as the 22 is the one forwarded to git. Also note the `-C 1`
this is to reduce concurrency and only reload 1 LB at a time

### Disable a whole service in a load balancer

A service is a host and port, this is useful when we want to isolate a given worker and get it out of the load balancing rotation.

To do so we will need to run one chef command:

```
knife ssh -p 2222 -a ipaddress -C 2 role:gitlab-base-lb "echo 'disable server https_git/git01.fe.gitlab.com' | sudo socat stdio /run/haproxy/admin.sock"
```

This will issue a `disable server` to the HAProxy administration socket commanding to put the service down for the given server.

#### Enable the service back up

The same technique, but enable instead of disable:

```
knife ssh -p 2222 -a ipaddress -C 2 role:gitlab-base-lb "echo 'enable server https_git/git01.fe.gitlab.com' | sudo socat stdio /run/haproxy/admin.sock"
```

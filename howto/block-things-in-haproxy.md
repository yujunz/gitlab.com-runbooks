# Blocking things in HAProxy load balancer

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
to do so you will need to issue the command `bundle exec rake "edit_role[gitlab-cluster-lb]"` from the
chef-repo folder with knife properly configured.

The value to change is "https_custom_config", be careful to respect spaces and to keep previous values:
``` json
  "override_attributes": {
    "gitlab-nfs-cluster": {
      "haproxy": {
        "chef_vault": "gitlab-cluster-lb",
        "worker_chef_query": "role:gitlab-cluster-worker",
        "server_timeout": "1h",
        "https_custom_config": "  acl mash2k3_uri path_beg -i /mash2k3/mash2k3-repository/raw/\n  http-request deny if mash2k3_uri\n  acl kexuejin_raw_uri pat
      }
    }
```

### Samples of configurations:

#### Deny a path with the DELETE http method

```
acl is_stop_impersonation  path_beg         /admin/users/stop_impersonation
acl is_delete method DELETE
http-request deny if is_delete is_stop_impersonation
```

### Once the changes are applied

Remember to run the chef-client in all the LBs
`knife ssh -p2222 -aipaddress role:gitlab-cluster-lb  'sudo chef-client'`

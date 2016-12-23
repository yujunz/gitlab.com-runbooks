# Creating runners manager node

## Prerequisites

1. If you are moving a node from one location to another and using the same token, please follow the below steps first. Otherwise, there will be a split brain situation and VMs will not be deleted properly.
  * Stop the gitlab-runner
  * Cleanup old docker-machines `/root/machines-operation.sh remove-all`
  * Start gitlab-runner on new server
1. Digital Ocean API [token](https://www.digitalocean.com/community/tutorials/how-to-use-the-digitalocean-api-v2).
1. [Registration Token](https://gitlab.com/admin/runners) from GitLab.com, tags for gitlab runner registration.
1. If cache used, cache url, access and secret key. For NYC1 DC - registry url is `http://runners-cache-2-internal.gitlab.com:444`, for NYC2 - `http://runners-cache-1-internal.gitlab.com:444`. Access and secret keys can be obtained in the vaults for `gitlab-ce-ee-runners` and `gitlab-shared-runners` roles.
1. If registry proxy is used, specify proxy url. For NYC1 DC - registry url is `http://runners-cache-2-internal.gitlab.com:1444`, for NYC2 - `http://runners-cache-1-internal.gitlab.com:1444`.
1. If manager being created not in DO, then you should use following addresses - `https://runners-cache-2.gitlab.com` for cache and `https://runners-cache-2.gitlab.com:1443` for registry.

## Steps to create runners manager node for GitLab.com

### Prepare node

Prepare droplet in `GitLab prod team` on DO and chose corresponding DC. Prefer NYC1 or NYC3 over NYC2. Runners cache and registry are limited in disk space on NYC2. [Bootstrap](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/doc/new-vps.md) droplet with chef.

### Create role and secrets

Create role ([sample](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/roles/gitlab-ce-ee-runners.json)) and corresponding secrets.

This is the main attributes which must be configured:

```
"cookbook-gitlab-runner" : {
  "runners" : {
    "docker-auto-scale" : {
      "machine" : {
        ...
      },
      "cache" : {
        ...
      }
    }
  }
}
```

In secrets you should configure following attributes:

```
cookbook-gitlab-runner:
  digitalocean_tokens:
    gitlab-shared-runners-manager-1.gitlab.com:
      docker_auto_scale: <docker token>
  runner_tokens:
    gitlab-shared-runners-manager-1.gitlab.com:
      docker_auto_scale: <runner token - obtained on the next step>
  runners:
    docker_auto_scale:
      cache:
        AccessKey: <cache key>
        SecretKey: <cache secret>
      machine:
        MachineOptions:
          digitalocean-region=<dc name>
          digitalocean-size=<droplet size>
          engine-registry-mirror=<registry url>
```

after creating and applying role and secrets run `chef-client`.

### 

### Register runner

After runner installation run `sudo gitlab-runner register` and specify following:

1. CI Url - `https://gitlab.com/ci`
1. GitLab.com token to register runner
1. Name (can be default - it is hostname)
1. Tags via comma

After creating runner obtain `token` value from `[[runners]]` section in `/etc/gitlab-runner/config.toml` for the name you used during registration. After update token value in role secret and run `chef-client` again. 

## Troubleshooting

### Certificate error

If you see errors like this 
```
ERROR: Error creating machine: Error checking the host: Error checking and/or regenerating the certs: There was an error validating certificates for host "67.205.151.216:2376": remote error: bad certificate  driver=digitalocean name=runner-ab89f037-auto-scale-1480005499-6b4ed8e5 operation=create
ERROR: You can attempt to regenerate them using 'docker-machine regenerate-certs [name]'.  driver=digitalocean name=runner-ab89f037-auto-scale-1480005499-6b4ed8e5 operation=create
ERROR: Be advised that this will trigger a Docker daemon restart which will stop running containers.  driver=digitalocean name=runner-ab89f037-auto-scale-1480005499-6b4ed8e5 operation=create
```

Then you should follow these steps to resolve this error:
1. stop gitlab-runner
1. delete directory `/root/.docker/machine`
1. create docker machine with the settings from `config.toml`
```
docker-machine create --driver=digitalocean --digitalocean-image coreos-stable --digitalocean-ssh-user core --digitalocean-access-token=<DO token> --digitalocean-region=<DC> --digitalocean-size=2gb --digitalocean-private-networking --digitalocean-userdata=/etc/gitlab-runner/cloudinit.sh test-machine
```
1. start gitlab-runner

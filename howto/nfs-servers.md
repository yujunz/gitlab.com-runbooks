# Git NFS Servers

Currently, we run 16 NFS servers for git repository data, with 4 of them being used for new projects.
Once the 4 servers for new projects reach 60% capacity, we build 4 new ones and set them to be the default.


## Building

In order to build a new NFS server, you will add the necessary definitions to the [GitLab terraform repository](https://gitlab.com/gitlab-com/gitlab-com-infrastructure).
It is easiest to do some sedops and simply copy a server definition like [the one for nfs-file-12](https://gitlab.com/gitlab-com/gitlab-com-infrastructure/blob/master/environments/production/virtual-machines/storage/main.tf#L3711-4058), updating it to use the numbers you need.

As of now, the terraform configuration for storage nodes uses a username/password combination from `common.env` in
the private env_vars of the terraform repo. Please be sure that you set `TF_VAR_first_user_password` to something you
know as you will need it to log in and configure the servers.

## Configuring 

Once you build the servers, you will need to manually create the LVM volume group, logical volume, and format the
volume with XFS. Then, mount the volume on to `/var/opt/gitlab` before proceeding to bootstrap with chef.

bootstrap them into chef. Each NFS server uses a unique role such as
[gitlab-base-stor-nfs-file-16](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/roles/gitlab-base-stor-nfs-file-16.json).
Be sure to create a role like this for each new NFS server.

When you run `chef-client` for the first time, it will install omnibus and configure it, however it does NOT
automatically create `/var/opt/gitlab/git-data`. You will need to manually create the directory else mounting
on the fleet will fail.

## Deploying

Once the servers have been configured as above, you will need to actually mount them on the fleet and tell the GitLab
application about them. This is done via updates to the `gitlab-base` and `canary-base` roles. You can see the
required changes in the [merge request](https://dev.gitlab.org/cookbooks/chef-repo/merge_requests/1380/diffs)
that the most recent NFS servers were added in.

After updating chef, the fleet should mount the NFS servers and update the application itself. If the rollout is successful,
you will need to send a HUP to the sidekiq-cluster processes on our sidekiq fleet. For whatever reason, sidekiq requires
a HUP after updating the storage locations in `gitlab.rb` but `gitlab-ctl reconfigure` does not do that for you. This led to 
some interesting and obscure failures when we most recently added NFS servers.

Create a NEW project and use the API to [move it to a new NFS server](https://gitlab.com/gitlab-com/runbooks/blob/master/howto/sharding.md) before pushing any data to it. 
Now that the project is moved, push some data to it and ensure that everything works. Namely, be sure that the
web interface updates with the data you've pushed. 

If all of the above works, use your admin account to change [where new projects are stored](https://docs.gitlab.com/ee/administration/repository_storage_paths.html#choose-where-new-project-repositories-will-be-stored)!

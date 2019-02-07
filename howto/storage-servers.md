# Git Storage Servers

Currently, we run 24 storage servers for git repository data, with 4 of them being used for new projects.
Once the 4 servers for new projects reach 60% capacity, we build 4 new ones and set them to be the default.


## Building

In order to build a new storage server, you will add the necessary definitions to the [GitLab terraform repository](https://gitlab.com/gitlab-com/gitlab-com-infrastructure). 
With the move to GCP, this is quite simple. All you must do is bump the number of `multizone-stor`
servers in the variables.tf. DO NOT increase the number of `stor` servers. We should only build multi-zone servers from now on.

## Configuring

Thanks to our bootstrap script, no manual configuration is needed. However,
it does NOT automatically create `/var/opt/gitlab/git-data`.
You will need to manually create the directory.

## Deploying

Once the servers have been configured as above, you will need to tell the GitLab
application about them. This is done via updates to the `gprd-base` and `gprd-base-stor-gitaly`
role.

The `gprd-base` role will need to be updated with the Gitaly storage targets
as seen in [this MR](https://dev.gitlab.org/cookbooks/chef-repo/merge_requests/2419/diffs#d38d00ba2c0e0e3043780492adc276b5b9cf6b32_421_446).
Please note, you no longer need to add mount data, only the Gitaly storage targets.
You will also need to add the new servers to the `gprd-base-stor-gitaly` role otherwise Gitaly
will not know about the new servers which will cause strange errors.

Create a NEW project and use the API to [move it to a new storage server](https://gitlab.com/gitlab-com/runbooks/blob/master/howto/sharding.md) before pushing any data to it.
Now that the project is moved, push some data to it and ensure that everything works. Namely, be sure that the
web interface updates with the data you've pushed.

If all of the above works, use your admin account to change [where new projects are stored](https://docs.gitlab.com/ee/administration/repository_storage_paths.html#choose-where-new-project-repositories-will-be-stored)!

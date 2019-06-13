# Git Storage Servers

Currently, we run 24 storage servers for git repository data, with 4 of them being used for new projects.
Once the 4 servers for new projects reach 60% capacity, we build 4 new ones and set them to be the default.

here's a [recording](https://drive.google.com/file/d/1d2OnABnaMKVlBCQWj_GLpaNN4N4Z1v7R/view) from one time when we had to add new nodes


## Building

In order to build a new storage server, you will add the necessary definitions to the [GitLab terraform repository](https://gitlab.com/gitlab-com/gitlab-com-infrastructure).
With the move to GCP, this is quite simple. All you must do is bump the number of `multizone-stor`
servers in the variables.tf. DO NOT increase the number of `stor` servers. We should only build multi-zone servers from now on.

## Configuring

Thanks to our bootstrap script, no manual configuration is needed. However,
it does NOT automatically create `/var/opt/gitlab/git-data/repositories`.
You will need to manually create the directory:
```
$ sudo mkdir -p /var/opt/gitlab/git-data/repositories
$ sudo chown git:git /var/opt/gitlab/git-data/
$ sudo chown git:git /var/opt/gitlab/git-data/repositories/
```

## Deploying

Once the servers have been configured as above, you will need to tell the GitLab
application about them. This is done via updates to the `gprd-base` and `gprd-base-stor-gitaly`
role.

The `gprd-base` role will need to be updated with the Gitaly storage targets
as seen in [this MR](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/merge_requests/2419/diffs#d38d00ba2c0e0e3043780492adc276b5b9cf6b32_421_446).
Please note, you no longer need to add mount data, only the Gitaly storage targets.
You will also need to add the new servers to the `gprd-base-stor-gitaly` role otherwise Gitaly
will not know about the new servers which will cause strange errors.

Create a NEW project and use the API to [move it to a new storage server](https://gitlab.com/gitlab-com/runbooks/blob/master/howto/sharding.md) before pushing any data to it.
Now that the project is moved, push some data to it and ensure that everything works. Namely, be sure that the
web interface updates with the data you've pushed.

If all of the above works, use your admin account to change [where new projects are stored](https://docs.gitlab.com/ee/administration/repository_storage_paths.html#choose-where-new-project-repositories-will-be-stored)!


  * [x] run `chef-client` until there's no errors. If the `gitlab-ee` packages is not installed try using `apt-get update` command. (see comments below for more info)
  * [x] create `/var/opt/gitlab/git-data/repositories` manually
  * [ ] from the console machine, tmux, stop chef-client on prod machines that had their roles edited in the chef MR

```bash
$ knife ssh -C 5 "roles:gprd-base-stor-gitaly OR roles:gprd-base" "sudo service chef-client stop"
```

  * [ ] update chef-config: https://ops.gitlab.net/gitlab-cookbooks/chef-repo/merge_requests/1202
  * [ ] do a dry run on one old gitaly machine, one new gitaly machine, one web machine, confirm the changes are as desired:
```bash
$ knife ssh 'name:web-cny-01-sv-gprd.c.gitlab-production.internal' 'sudo chef-client --why-run'
$ knife ssh 'name:file-01-stor-gprd.c.gitlab-production.internal' 'sudo chef-client --why-run'
$ knife ssh 'name:file-33-stor-gprd.c.gitlab-production.internal' 'sudo chef-client --why-run'
```
  * [ ] force a chef-client run on gitaly nodes (if you run chef on web/api nodes, they would be trying to connect to gitaly nodes before they were ready):
```bash
$ knife ssh -C 2 "roles:gprd-base-stor-gitaly" "sudo chef-client"
```
  * [ ] check gitaly logs to confirm they are fine
  * [ ] run chef-client on remaining machines, gradually:
```bash
$ knife ssh -C 2 "roles:gprd-base" "sudo chef-client"
```
  * [ ] verify new storage nodes are operational ([doc](https://gitlab.com/gitlab-com/runbooks/blob/master/howto/storage-servers.md#deploying)):
    - create project on gitlab.com
    - using GL api ([doc](https://gitlab.com/gitlab-com/runbooks/blob/master/howto/sharding.md#manual-method)), move it to new storage node
    - push some date to the new project
    - check in the web UI if everything is ok
  * [ ] change where new projects are stored (set 3 new nodes as defaults, leave 1 for rebalancing of old nodes): https://docs.gitlab.com/ee/administration/repository_storage_paths.html#choose-where-new-project-repositories-will-be-stored

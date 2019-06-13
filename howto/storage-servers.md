# Git Storage Servers

Currently, we run 24 storage servers for git repository data, with 4 of them being used for new projects.
Once the 4 servers for new projects reach 60% capacity, we build 4 new ones and set them to be the default.

here's a [recording](https://drive.google.com/file/d/1d2OnABnaMKVlBCQWj_GLpaNN4N4Z1v7R/view) from one time when we had to add new nodes


## Building VMs

In order to build a new storage server, you will add the necessary definitions to the [GitLab terraform repository](https://gitlab.com/gitlab-com/gitlab-com-infrastructure).
With the move to GCP, this is quite simple. All you must do is bump the number of `multizone-store`
servers in the variables.tf. DO NOT increase the number of `stor` servers. We should only build multi-zone servers from now on.

## Initial configuration

Thanks to our bootstrap script, no manual configuration is needed. However,
it does NOT automatically create `/var/opt/gitlab/git-data/repositories`.
You will need to manually create the directory:
```
$ sudo mkdir -p /var/opt/gitlab/git-data/repositories
$ sudo chown git:git /var/opt/gitlab/git-data/
$ sudo chown git:git /var/opt/gitlab/git-data/repositories/
```

make sure `chef-client` runs without any errors!
check that the gitaly service is running: `gitlab-ctl status gitaly` and there are no errors in logs in `/var/log/gitlab/gitaly/current`

## Gitlab application configuration

Once the servers have been configured as above, you will need to tell the GitLab
application about them. This is done via updates to the `gprd-base` and `gprd-base-stor-gitaly`
role.

The `gprd-base` role will need to be updated with the Gitaly storage targets
as seen in [this MR](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/merge_requests/2419/diffs#d38d00ba2c0e0e3043780492adc276b5b9cf6b32_421_446).
Please note, you no longer need to add mount data, only the Gitaly storage targets.
You will also need to add the new servers to the `gprd-base-stor-gitaly` role otherwise Gitaly
will not know about the new servers which will cause strange errors.

In order to roll out new config:
1. prepare an MR in the `chef-repo` with the relevant changes
1. from the console machine, tmux, check status of chef on prod machines that had their roles edited in the chef MR
```bash
$ knife ssh -C 5 "roles:gprd-base-stor-gitaly OR roles:gprd-base NOT name:bastion-01-inf-gprd.c.gitlab-production.internal NOT name:bastion-02-inf-gprd.c.gitlab-production.internal NOT name:bastion-03-inf-gprd.c.gitlab-production.internal" "sudo systemctl is-active chef-client.service"
```
1. now stop chef-client on those nodes:
```bash
$ knife ssh -C 5 "roles:gprd-base-stor-gitaly OR roles:gprd-base NOT name:bastion-01-inf-gprd.c.gitlab-production.internal NOT name:bastion-02-inf-gprd.c.gitlab-production.internal NOT name:bastion-03-inf-gprd.c.gitlab-production.internal" "sudo systemctl stop chef-client.service"
```
1. merge the MR in the `chef-repo` that you prepared earlier
1. do a dry run on one old gitaly machine, one new gitaly machine, one web machine and confirm the changes are as desired, for example:
```bash
$ knife ssh 'name:web-cny-01-sv-gprd.c.gitlab-production.internal' 'sudo chef-client --why-run'
$ knife ssh 'name:file-01-stor-gprd.c.gitlab-production.internal' 'sudo chef-client --why-run'
$ knife ssh 'name:file-33-stor-gprd.c.gitlab-production.internal' 'sudo chef-client --why-run'
```
1. force a chef-client run on gitaly nodes (if you run chef on web/api nodes at this point they would be trying to connect to gitaly nodes before they were ready):
```bash
$ knife ssh -C 2 "roles:gprd-base-stor-gitaly" "sudo chef-client"
```
1. check gitaly logs to confirm they are fine
1. run chef-client on remaining machines, gradually:
```bash
$ knife ssh -C 2 "roles:gprd-base" "sudo chef-client"
```

## Testing new nodes ##

To confirm new storage nodes are operational:
1. Create a NEW project, do not push any data to it
1. Use the API to [move it to a new storage server](https://gitlab.com/gitlab-com/runbooks/blob/master/howto/sharding.md) before pushing any data to it
1. Now that the project is moved, push some data to it and ensure that everything works. Namely, be sure that the
web interface updates with the data you've pushed.

## Configuring Gitlab to use new storage nodes ##

If all of the above works, use your admin account to change [where new projects are stored](https://docs.gitlab.com/ee/administration/repository_storage_paths.html#choose-where-new-project-repositories-will-be-stored)!

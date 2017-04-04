# Backups and restore
We currenty have multiple backup solutions:
- AWS snapshots by `ebs.gitlap.com`
- Azure snapshots by `azure.gitlap.com`
- GitLab backup for database and pages

## AWS snapshots
### Snapshots
Every night on `ebs.gitlap.com` the following snapshot script `/opt/gitlab-backup/bin/gitlab-ebs-snapshot` creates snapshots for all EC2 instances.
### Restore
https://dev.gitlab.org/cookbooks/gitlab-backup/blob/master/doc/gitlab-ebs-snapshot.md#restoring

## Azure snapshots
### Snapshots
Every night on `azure.gitlap.com` the following snapshot script `/opt/gitlab-backup/bin/gitlab-azure-snapshots` creates snapshots for the Azure instances mentioned in `/etc/gitlab-azure-snapshots.yml`.

Just add the chef role `"role[azure-snapshot]"` to a node and snapshots will be created.

### Restore
On `azure.gitlap.com` you can use script `/opt/gitlab-backup/bin/gitlab-azure-restore` to restore the snapshots and attach the data disks to a new created instance.

So to restore i.e. file-storage1.cluster.gitlab.com follow these steps:
#### Create new node
```
~/chef-repo/tools/bin/azure-create-node --role backend file-storage2.cluster.gitlab.com
```
#### Restore snapshot and attach the data disks
Login into `azure.gitlap.com`

You can get a list of available epochs by checking the snapshot info files in /var/lib/gitlab-azure-snapshots:
```
ls -al /var/lib/gitlab-azure-snapshots/
```
Restore snapshots:
```
/opt/gitlab-backup/bin/gitlab-azure-restore --epoch 1463965202 --source file-storage1.cluster.gitlab.com file-storage2.cluster.gitlab.com
```

#### Activate logical volume
Activate the logical volume in the new created node:
```
# LVM support
sudo apt-get install -y lvm2
# look for gitlab_vg on the attached drives
sudo vgchange -ay gitlab_vg
# make sure the mountpoint exists
sudo mkdir -p /var/opt/gitlab
# mount the logical volume at /var/opt/gitlab
sudo mount /dev/gitlab_vg/gitlab_com /var/opt/gitlab
```

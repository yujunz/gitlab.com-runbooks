# Azure Snapshots

In order to back up git/uploads/lfs/artifact files, we use Azure snapshots.
These snapshots are created by a cron on the `azure.gitlap.com` server using a
[ruby script](https://gitlab.com/gitlab-cookbooks/gitlab-backup/blob/master/files/default/azure-ruby-scripts/gitlab-azure-snapshots). 
They are cleaned up by a similar cron using a [cleanup script](https://gitlab.com/gitlab-cookbooks/gitlab-backup/blob/master/files/default/azure-ruby-scripts/gitlab-azure-snapshots-cleanup).

## Snapshot Creation and Cleanup

At 1AM UTC, the snapshot creation script runs. It creates a resource group with
the name `snapshots-YYYY-MM-DD`. It then takes snapshots of each file server's disks and 
places them within that resource group. The snapshots are named in the format of
`file-01-datadisk-01-snap-YYYY-MM-DD`.

At 3AM UTC, the snapshot cleanup script runs. This script simply checks for resource groups in the above format and deletes them if the date is more than 14 days ago.

## How do I restore?

Currently the restore is an extremely manual process. We hope to create a more
automated way of restoring soon. The below guide assumes that you must create a new server and that you are not attempting to reattach to an already existing server.

1. Create an Ubuntu server in Azure.
1. Create disks from the snapshots, placing them in the same resource group as the server
created in step 1. You can do this via a bash one-liner with the Azure CLI.

    ```
    for i in {0..15}; do az disk create -g azure-snapshot-restore-file-08 -n file-08-restore-$i --source /subscriptions/c802e1f4-573f-4049-8645-4f735e6411b3/resourceGroups/STORAGEPROD/providers/Microsoft.Compute/snapshots/file-08-datadisk-$i-snap-2017-05-03; done
    ```

1. Attach those disks to the new server

    ```
    for i in {0..15}; do az vm disk attach -g azure-snapshot-restore-file-08 --disk file-08-restore-$i --vm-name azure-snapshot-restore-file-08 --lun $i; done
    ```

1. Once all of the disks are attached, check to make sure that all of the LVM things look good. They should look something like this: 

    ```
    root@azure-snapshot-restore-file-08:~# pvs
    PV         VG        Fmt  Attr PSize    PFree
    /dev/sdc   gitlab_vg lvm2 a--  1023.00g    0
    /dev/sdd   gitlab_vg lvm2 a--  1023.00g    0
    /dev/sde   gitlab_vg lvm2 a--  1023.00g    0
    /dev/sdf   gitlab_vg lvm2 a--  1023.00g    0
    /dev/sdg   gitlab_vg lvm2 a--  1023.00g    0
    /dev/sdh   gitlab_vg lvm2 a--  1023.00g    0
    /dev/sdi   gitlab_vg lvm2 a--  1023.00g    0
    /dev/sdj   gitlab_vg lvm2 a--  1023.00g    0
    /dev/sdk   gitlab_vg lvm2 a--  1023.00g    0
    /dev/sdl   gitlab_vg lvm2 a--  1023.00g    0
    /dev/sdm   gitlab_vg lvm2 a--  1023.00g    0
    /dev/sdn   gitlab_vg lvm2 a--  1023.00g    0
    /dev/sdo   gitlab_vg lvm2 a--  1023.00g    0
    /dev/sdp   gitlab_vg lvm2 a--  1023.00g    0
    /dev/sdq   gitlab_vg lvm2 a--  1023.00g    0
    /dev/sdr   gitlab_vg lvm2 a--  1023.00g    0 
    root@azure-snapshot-restore-file-08:~# vgs
    VG        #PV #LV #SN Attr   VSize  VFree
    gitlab_vg  16   1   0 wz--n- 15.98t    0
    azure-snapshot-restore-file-08 lvs
    LV         VG        Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
    gitlab_var gitlab_vg -wi-ao---- 15.98t
    ```

1. You now should attempt to mount the filesystem. This may or may not work as expected.
    There is currently no way to ensure that all of the disks on a system are snapshotted at *exactly* the same time. 
    As such, it is possible that the filesystem will be corrupted or not mount.
    However, `xfs_repair` will not work unless you try to mount the filesystem first.
    If the mount command works and does not give an error, this is the last step.

    You should see:

    ```
    root@azure-snapshot-restore-file-08:~# mount /dev/gitlab_vg/gitlab_var /path/to/mountpoint
    ```

    If you see an error like the following, please proceed to the next section.

    ```
    root@azure-snapshot-restore-file-08:~# mount /dev/gitlab_vg/gitlab_var /path/to/mountpoint
    <note to self, find the actual error message to paste here>
    ```

### IF the mount command gives an error 

If the mount command gives an error, you will need to run `xfs_repair`. This command
will take around 2 hours to complete. 

1. Run the `xfs_repair` command

    ```
    root@azure-snapshot-restore-file-08:~#  xfs_repair /dev/mapper/gitlab_vg-gitlab_var
    ```

    The output of this command will be VERY long. Instead of pasting it here, please review [an example restore attempt](https://gitlab.com/gitlab-com/infrastructure/issues/1698#note_28693997).

1. Once `xfs_repair` is finished, you can mount it again. There should be no errors.

    ```
    root@azure-snapshot-restore-file-08:~# mount /dev/gitlab_vg/gitlab_var /path/to/mountpoint
    ```

1. Now you can go find whatever you are looking for.
If this is a complete restore from absolute and complete disaster, you can just mount the filesystem on `/var/opt/gitlab` as expected and go from there.

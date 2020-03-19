# Google Cloud Snapshots

We take snapshots of each disk with the label `do_snapshots=true`.
We use the [gitlab-production-snapshots](https://gitlab.com/gitlab-restore/gitlab-production-snapshots)
project to take snapshots daily using a scheduled CI job. We keep 14 days worth of snapshots.

Currently all snapshot restores are manual. We will be creating a script
to automate this, but until then the manual steps are recorded here. Once
the script exists, this runbook should be updated to include info on how
to use that script.

The first test of these snapshots can be found in [this issue](https://gitlab.com/gitlab-com/migration/issues/560).

## Manual Restore Procedure

1. Manually create a server in GCP. Sizing doesn't matter too much here.
1. Create disks from the snapshots you wish to restore/test. The snapshots have weird names. They should be standardized, but you can find the snapshots in the GCP panel and search by source server name.
1. Attach these disks to the server created in step one. If you are trying to test multiple disks, you can attach them all to the same server.
1. Run an `fsck` on the disk(s) that you wish to test. This will potentially take over an hour for large disks like file servers, but are much faster for smaller servers. I tested with `time fsck -fy /dev/sdX`.
1. If the `fsck` finishes successfully, mount the disk(s) and run a find to exercise the disk. In my test I mounted all the disks to `/mnt/<disk name>` and then ran a `find` to go through /mnt/ and thus all the disks. This could be improved.
1. This is all that was tested in our initial tests, but more could be added. You may now delete the test server and disks.

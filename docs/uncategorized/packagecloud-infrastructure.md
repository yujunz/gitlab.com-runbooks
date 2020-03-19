# PackageCloud Infrastructure and Backups

This document will cover how our packagecloud infrastructure works, how
backups are taken, and how to restore said backups. `packages.gitlab.com`
is hosted in AWS us-west-1 (N. California). There are also
[PackageCloud docs](https://packagecloud.atlassian.net/wiki/display/ENTERPRISE/Backups)
on the entire backup process.

## How Does PackageCloud Work?

PackageCloud is provided as an omnibus package, just like GitLab. This
package includes everything that one would need to begin using PackageCloud.
We install and configure PackageCloud via the [gitlab-packagecloud](https://gitlab.com/gitlab-cookbooks/gitlab-packagecloud) chef cookbook. The
omnibus package contains:

* mysql
* nginx
* rainbows
* redis
* resque
* unicorn

Most notably, PackageCloud uses MySQL, not PostgreSQL like most of our
applications.

We have configured PackageCloud to send all of the packages to an S3 bucket.
When a package is pushed to the repo, it is automatically uploaded to S3. We use
CloudFront to put package downloads behind a CDN. The configuration of
CloudFront and all associated services was done by PackageCloud itself via
`packagecloud-ctl`. The credentials for CloudFront and the S3 bucket are stored
in the `chef-vault`

## What Is Backed Up?

PackageCloud is currently set up to back up its database only, once per day.
These backups are placed in `/var/opt/packagecloud/backups/packagecloud-streamed-database-backup.<unix timestamp>.xbstream`,
and are also uploaded to the `gitlab-packagecloud-db-backups` S3 bucket. Backups
are kept for 14 days.

The config is not backed up as it is safely in Chef.

There is no need to back up the packages themselves as they are already stored in S3.
It is unlikely that we will ever have the need to restore packages, but the packages
bucket uses Amazon's [cross-region replication](http://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html)
so that we can have extra certainty that the packages will survive.


## How Is the DB Backed Up?

The native PackageCloud backups use [xbstream](https://www.percona.com/doc/percona-xtrabackup/LATEST/xbstream/xbstream.html).
This creates a full backup of the MySQL data without locking the database for the
entire backup.

## What can go wrong?

We have a Dead Man's Snitch that should notice the job not running (no changes to the S3 bucket) or being somehow broken/stalled, and e-mail ops-contact+packagecloudbackups@gitlab.com

In one case, the upload to S3 was stalled/locked, and no further backups were running (they run under sv; when one finishes it exits, sv starts the job again which immediately sleeps for 1 day before doing the next backup.  If it stalls/locks up, that's it until we take action).  This manifested as:
1. a very long running process that was doing nothing,
2. The last line of /var/log/packagecloud/database-backups/current being something like `uploading backups/packagecloud-streamed-database-backup.DATESTAMP/packagecloud-streamed-database-backup.DATESTAMP.xbstream`, and nothing else showing the backup completing
3. `sudo packagecloud-ctl status database_backups` indicating a very long lifetime for the service process

It can be resolved by restarting the service:

`sudo packagecloud-ctl restart database_backups`

which kills off the stuck process cleanly, and starts a new one.  The next backup will occur in approximately 24 hours after the sleep expires.

## So How Do We Actually Restore for testing?

We're glad you asked! This process is subject to substantial change as we work out
the problems with uploading to S3 automatically and the giant database. The following
guide assumes that there has been a catastrophic event that will require a complete
rebuild and will thus begin with building and configuring the server.

There are two ways to build the server:

### Building it the semi-automated way
1. Make sure your `aws` cli is working (`aws ec2 describe-vpcs` as test cmd)
1. `mkdir ./bad && cd ./bad`
1. grab backup_scripts/04-packagecloud.sh
1. `time bash 04-packagecloud.sh`
1. As soon as cloud-init is done (`tail -f /var/log/cloud-init-output.log`),
   you can proceed with configuring secrets for packagecloud.

### Building it the manual way

1. Build a new server! The current specs are listed below.
  * Instance Size: c4.2xlarge
  * Root Disk Size: 8GB (gp2)
  * Data Disk Size: 2TB (gp2), xfs, mounted on /var/opt/packagecloud
  * OS: Ubuntu 14.04 LTS
  * Security Groups With Inbound Ports:
    * 80
    * 443
    * 22
    * Standard monitoring ports, available only to prometheus servers

### Configuring the server

1. Add the newly created server to [chef-repo](https://ops.gitlab.net/gitlab-cookbooks/chef-repo) with the
   the current `packages.gitlab.com` node as a template.
2. Once you run chef-client on the new server, it will automatically set the config
   up for you. Alternatively, you can manually install packagecloud by:
     * getting the deb repo url from `/etc/apt/sources.list.d/computology_packagecloud-enterprise_.list` on `packages.gitlab.com`
     * installing it via `apt-get update && apt-get install packagecloud`
     * copying the `/etc/packagecloud/packagecloud.rb` file from `packages.gitlab.com`. Currently we are only testing restore,
       therefore you can comment out the `ssl` and `backups` settings.
     * running `packagecloud-ctl reconfigure`
3. Install s3cmd and use the credentials in the `packagecloud.rb` file for the credentials.
4. Download the most recent backup from `s3://gitlab-packagecloud-db-backups/backups` and place it in `/var/opt/packagecloud/backups/`.
5. The restore command will extract a large amount of data to `/tmp`. To make sure you don't run out of space you can:
    ```
    mkdir /var/opt/packagecloud/tmp
    mount --rbind /var/opt/packagecloud/tmp /tmp
    ```
6. Run the restore command `packagecloud-ctl backup-database-restore /var/opt/packagecloud/backups/<name of tgz file>`
This step will take around 2 hours. As the database grows, so too will this time.
Be certain to run this step in `screen` or `tmux`!
1. Unmount the `tmp` folder with `umount /var/opt/packagecloud/tmp`

## Credentials

### Package key

The package key is used for the prerelease repo which is used for
all GitLab deployments that pull packages from

```
repo:    gitlab/pre-release
```

We do not let the wider community pull from this repo because GitLab.com
production and non-production environments use it for testing security updates
and unreleased builds before they are released.

#### Key rotation

* To rotate the package key visit
https://packages.gitlab.com/gitlab/pre-release/tokens and select `rotate`

* Update the secret in each environment, for example:
```
    ./bin/gkms-vault-edit gitlab-omnibus-secrets gprd
    ./bin/gkms-vault-edit gitlab-omnibus-secrets gstg
    ./bin/gkms-vault-edit gitlab-omnibus-secrets ops
    ./bin/gkms-vault-edit gitlab-omnibus-secrets dev
    ./bin/gkms-vault-edit gitlab-omnibus-secrets dr
    ./bin/gkms-vault-edit gitlab-omnibus-secrets pre
    ./bin/gkms-vault-edit gitlab-omnibus-secrets testbed

# ... and change the following

  "omnibus-gitlab": {
    "package": {
      "key": "abc123"
    },

```
* _Note: For an updated list of envs see https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/bin/gkms-vault-common#L56_
* Because of https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/7459 , after the update chef runs will fail because the sources file is not updated
  automatically, the following knife command can workaround the issue:
```
knife ssh -C10  "recipes:omnibus-gitlab\\:\\:default" "sudo rm -f /etc/apt/sources.list.d/gitlab_pre-release.list"
```
* Verify that chef runs complete successfully after deleting the sources file

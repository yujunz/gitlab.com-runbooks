# PackageCloud Infrastructure and Backups

This document will cover how our packagecloud infrastructure works, how
backups are taken, and how to restore said backups. `packages.gitlab.com`
is hosted in AWS us-west-1 (N. California).

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

We have configured PackageCloud to send all of the packages to an S3
bucket. When a package is pushed to the repo, it is automatically uploaded
to S3. The credentials for the S3 bucket are located in chef-vault.

## What Is Backed Up?

PackageCloud is currently set up to back up its database only, once per day.
These backups are placed in `/var/opt/packagecloud/backups/packagecloud-database-backup.<unix_timestamp>.tgz`
The config is not backed up as it is safely in Chef.
The backups are kept for 10 days on disk. However, because of the absolutely massive
size of the database, PackageCloud itself cannot upload the backups to S3. Thus,
all of the backups are stored on disk at this time. We are working on this problem, but
as of now there are several backups in S3 that can be used in case of a catastrophic
event.

There is no need to back up the packages themselves as they are already stored in S3.
It is unlikely that we will ever have the need to restore packages, but the packages
bucket uses Amazon's [cross-region replication](http://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html)
so that we can have extra certainty that the packages will survive. Additionally,
we hope to eventually be able to switch the bucket on the fly should there ever
be a [large scale S3 outage](https://aws.amazon.com/message/41926/).


## How Is the DB Backed Up?

The native PackageCloud backups use [innobackupex](https://www.percona.com/doc/percona-xtrabackup/2.4/innobackupex/creating_a_backup_ibk.html). 
This creates a full backup of the MySQL data without locking the database for the 
entire backup. Additionally, the backup/restore of the database is also much faster 
than a normal mysqldump/SQL file import.
You can read more about how innobackupex works in Percona's [innobackupex documentation](https://www.percona.com/doc/percona-xtrabackup/2.4/innobackupex/how_innobackupex_works.html).
As of this writing, the database is over 600GB in size and takes multiple hours to back
up.

## So How Do We Actually Restore?

We're glad you asked! This process is subject to substantial change as we work out
the problems with uploading to S3 automatically and the giant database. The following
guide assumes that there has been a catastrophic event that will require a complete
rebuild and will thus begin with building and configuring the server.

1. Build a new server! The current specs are listed below.
  * Instance Size: c4.2xlarge
  * Root Disk Size: 1TG (gp2)
  * Data Disk Size: 16TB (gp2), xfs, mounted on /var/opt/packagecloud
  * OS: Ubuntu 14.04 LTS
  * Security Groups With Ports:
    * <do we want to put ports here? I do, nmap will give it all away anyway>
1. Add it to [chef-repo](https://dev.gitlab.org/cookbooks/chef-repo) with the
   the current `packages.gitlab.com` node as a template.
1. Once you run chef-client on the new server, it will automatically set the config
   up for you.
1. Install s3cmd and use the credentials in the `packagecloud.rb` file for the credentials.
1. Download the most recent backup from `s3://gitlab-packagecloud-db-backups/uploaded-backups` and place it in `/var/opt/packagecloud/backups/`.
1. Run the restore command `packagecloud-ctl backup-database-restore /var/opt/packagecloud/backups/<name of tgz file>` 
This step will take around 2 hours. As the database grows, so too will this time. 
Be certain to run this step in `screen` or `tmux`!
1. At this point, everything should be ready to go. If the elastic IP is unable to
be used for some reason, you will need to update DNS.

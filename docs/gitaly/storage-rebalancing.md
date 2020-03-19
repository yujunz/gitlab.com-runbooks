# GitLab Storage Re-balancing

Moving project repositories between `gitaly` storage shards presently
involves direct human intervention, which is obviously a less than
ideal arrangement. To help reduce the cognitive load involved in the
procedures involved, the following instructional walk-throughs are
documented here.

## Summary

Moving a project git repository from the file system of one `gitaly`
storage shard node to another is referred to as "migration".

A migration consists of both a *repository replication* and the update of
the name of the `repository_storage` field of the given `Project` in the
GitLab database.

Only if both of these operations succeed is a migration considered to have
successfully taken place.

In order to replicate a repository and update the database field which tracks
the residence of the project repository, the project repository must be marked
as read-only. Once the job has completed, the project must be marked back to
writable again by setting `project.repository_read_only = false`.

In order to orchestrate this, a `gitlab-rails` app feature is responsible
for scheduling a sidekiq job called `ProjectUpdateRepositoryStorageWorker`.
During invocation, activity for this job will appear in the kibana logs. For
example: https://log.gprd.gitlab.net/goto/1a02b96a7066e7c2cbacbf55e3d5947d

You may find the job implementation in the `gitlab` source code repository by
looking for the `project_update_repository_storage` method definition.

## Dashboards

The [Gitaly Rebalancing dashboard](https://dashboards.gitlab.net/d/gitaly-rebalancing/gitaly-rebalance-dashboard?orgId=1) is designed to assist with decision making
around manual re-balancing of repositories. It is recommended that this
dashboard is consulted before triggering a manual re-balance, to get an idea of
which servers are over-utilized and which ones are under-utilized.

## How to migrate a project repository

Over time, a couple of methods have been developed for accomplishing the
re-location of a project repository from one gitaly storage shard node file
system to another.

### Manual method

1. Login to gitlab.com using the admin account
2. Go to: https://gitlab.com/profile/personal_access_tokens and generate an admin API token, set expiration date at a few days, e.g. 3 days
3. Take note of the project ID. You will need it to move the project via the API. You can find it in the project page, next to the project avatar and under the project name
4. Prepare for the move.
  - ssh to the console machine: `ssh <your_username>@gprd-console`
  - start tmux
  - create and source a file with your API token:

```bash
$ cat ./export_token.sh

export PRIVATE_TOKEN=<your_api_token_here>
$ source ./export_token.sh
```

5. Trigger the move using the api.  Note that the project will automatically be set into read-only and set back to read-write after the move

```
curl --request PUT --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" -d repository_storage=nfs-fileXX https://gitlab.com/api/v4/projects/<project_to_move_id_here>
```

_Note_: The option of `repository_storage` is the destination gitaly shard and it's a short name as configured in the `git_data_dirs` options of the `gitlab.rb` file.

6. If needed, check logs for the sidekiq job in Kibana:
  - in Kibana Discover app, select `pubsub-sidekiq-inf-gprd` index pattern
  - search for `ProjectUpdateRepositoryStorageWorker`

7. Optional: confirm the new location and repository in the rails console

```ruby
ssh <your_username>-rails@gprd-console
p = Project.find_by_full_path('<my-namespace/my-group/my-project>')  # find by name
p = Project.find(<project_id>) # or by project id
p.repository_storage # check that it is the correct shard
p.repository_read_only? # this should be set to false
```

### Slightly automated method

A script exists in this repo,
[`scripts/storage_rebalance.rb`](../../scripts/storage_rebalance.rb).

The goal of this script is to select two file servers, one of which we want to
move data _OFF_, otherwise known as `current-file-server`, and one where we want
to move data _TO_, otherwise known as `target-file-server`.  We then select how
much data we'd like to move.  This script will then query all projects on that
file server, their repository size that is known in the `project statistics`
table and sort it by the project that was updated by data ascending.

Once this list of projects is built, the script submits a migration job that
sidekiq will attempt to carry out. The `wait` time specified is the time to
wait for that job to be completed. It is possible that the script will timeout
but that the sidekiq job is still running and completes successfully. You will
need to verify that the project file location is accurate and see if sidekiq
marked the repository as writable to verify this.

#### How to use it

1. Copy it to a location where the git user can access it on the console server.
   The console server might be a good location. `sudo mkdir -p /var/opt/gitlab/scripts; sudo mkdir -p /var/opt/gitlab/scripts/logs; sudo curl --silent https://gitlab.com/gitlab-com/runbooks/raw/master/scripts/storage_rebalance.rb --output /var/opt/gitlab/scripts/storage_rebalance.rb; sudo chmod +x /var/opt/gitlab/scripts/storage_rebalance.rb`
1. You will need a personal access token that has _API_ access using your admin
   account. This token will need to be exported as an environment variable,
   `PRIVATE_TOKEN`. `export PRIVATE_TOKEN=CHANGEME`
1. Invoke the script using the `--help` flag for usage details: `/var/opt/gitlab/scripts/storage_rebalance.rb --help` (A warning will appear because the script is not being ran with a `gitlab-rails runner`.  This is fine for now.)
1. See issue https://gitlab.com/gitlab-com/gl-infra/production/issues/664 for
   further inspiration
1. Or use this guideline below on how to conduct a production issue repo move.
   - Install the migration script on a common system (console server).
   - Dry run the migration script and look for problems.
   ```bash
   time gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --current-file-server=nfs-fileXX --target-file-server=nfs-fileYY --wait=10800 --move-amount=1000 --refresh-stats --validate-checksum --validate-size --dry-run=yes 2>&1 | tee "/var/opt/gitlab/scripts/logs/migration.$(date +%Y-%m-%d_%H:%M).log"
   ```
   - Execute the migration script in a tmux session on the console server during low utilization time period.
   ```bash
   time gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --current-file-server=nfs-fileXX --target-file-server=nfs-fileYY --wait=10800 --move-amount=1000 --refresh-stats --validate-checksum --validate-size --dry-run=yes 2>&1 | tee "/var/opt/gitlab/scripts/logs/migration.$(date +%Y-%m-%d_%H:%M).log"
   ```
   - Review any timed out transactions and restore/repair any repositories to their proper writable status.
   - **Note:** Make a note of the project identifiers of any failed repository replications, and add those identifiers to the `--skip` list parameter of the `storage_rebalance.rb` script.

#### Failure modes

There are currently many ways that a repository can fail to replicate onto the file system of another shard.

- **Commits validation failure**
  * This means that the most recent commit on the project before replication does not match the most recent commit of the project after replication.
  * There is no record of any occurrence of such a circumstance, but it could potentially be a very bad problem.
  * It is not known whether it is possible to recover from such a condition, and that alone warrants its own issue discussion.
- **Repository size failure**
  * The repository size is different according to the calculation as implemented in the gitlab-rails app.
  * This indicates that a roll-back is required.
  * The repository size statistic is refreshed immediately before replication, and immediately after replication.
  * In the case that the actual space on disk for the replica does not match that of the original, understand that such a situation is not necessarily a bad thing.  The gitlab rails repository size calculation is somewhat nuanced, and does not necessarily reflect comprehensive disk usage of a given repository.
  * Since a couple of recent bug fixes, there have been *no* recorded repository size validation check failures.
- **Checksum validation failure**
  * This means that the collective refs of the replica do not match the collection refs of the original.
  * This situation indicates that a roll-back is required.
- **Timeout**
  * This means that some process or `grpc` operation has taken too long, and did not complete within a pre-configured or programmatic parametric timeout.
  * This means that recovering from this situation will likely only involve the deletion of the incomplete repository replica from the file system of the new shard, or, only a partial roll-back.
  * It is highly unusual for an operation timeout error to lead to a situation where the database persists a state that a project's repository home is the new shard.

## Reviewing replicated repositories

It is useful, but not required, to record details about both the original
repository and the replica repository.

Copy the disk path of the project repository from the
`storage_rebalance.rb` script output of the "successful" migration.

### Install the info helper script

1. Secure shell to the source shard node system. For example: `ssh file-33-stor-gprd.c.gitlab-production.internal`
2. Download this script to the source shard node file system: `sudo mkdir -p /var/opt/gitlab/scripts; sudo curl --silent https://gitlab.com/gitlab-com/runbooks/raw/master/scripts/storage_repository_info.sh --output /var/opt/gitlab/scripts/storage_repository_info.sh; sudo chmod +x /var/opt/gitlab/scripts/storage_repository_info.sh`
3. Now exit the shell session to that shard node.
4. Repeat these steps for the the target node system.

### How to use it

Using the pretend disk path `@hashed/4a/68/4a68b75506effac26bc7660ffb4ff46cbb11ba00ed4795c1c5f0125f256d7f6a`:

```bash
export disk_path='@hashed/4a/68/4a68b75506effac26bc7660ffb4ff46cbb11ba00ed4795c1c5f0125f256d7f6a'
ssh file-33-stor-gprd.c.gitlab-production.internal "sudo /var/opt/gitlab/scripts/storage_repository_info.sh '${disk_path}'"
```

Users of macOS can make their lives easier using `pbcopy`:

```bash
ssh file-33-stor-gprd.c.gitlab-production.internal "sudo /var/opt/gitlab/scripts/storage_repository_info.sh '${disk_path}'" | pbcopy; pbpaste
```

You should execute the `info.sh` script on both the source and target shard node systems.

```bash
ssh file-43-stor-gprd.c.gitlab-production.internal "sudo /var/opt/gitlab/scripts/storage_repository_info.sh '${disk_path}'" | pbcopy; pbpaste
```

Record the results of these commands in the issue for the re-balancing
operations.  This may be useful diagnostic for other engineers.

## Rolling back failed replicas

It is possible for a repository to be left in an inconsistent state, even
though the `ProjectUpdateRepositoryStorageWorker` process has completed without
any errors.

The `storage_rebalance.rb` script is designed to detect some of these
inconsistencies. In the event that such a problem is detected, it will record
a message about the nature of the issue, and present it at the end of the
invocation, along with the project id of the inconsistent repository replica.

In the event of a project migration which encounters a time-out error, it is
very likely that a full roll-back will not be required. Instead, it is common
for a repository to be left in a very incomplete state on the target gitaly
shard file system, and the database is never updated to specify that the
project repository gitaly storage shard node has changed. Action indicated by
this scenario is only a partial roll-back, in which only the incomplete replica
repository on the target gitaly shard file system should be deleted. See the
`File system roll-back` section below for more details.

Always double-check with the database to determine where the `gitlab-rails` app
thinks that the project repository is stored. This information can be found in
the dry-run output of the `storage_revert.rb` script. See the
`Database roll-back` section below for more details.

A full roll-back is considered to be the execution of multiple operations, in
the following order:

1. Renaming back to their original paths both the repository directory for the `git` repository and the `wiki.git` repository on the source shard node file system.
2. Reverting back to the source shard node name the database `project.repository_storage` field.
3. Deleting the replica repositories on the target shard file system.

The order here is very important, because if the database is updated before the
original repository is renamed back to its original name, then the
`gitlab-rails` app will be unable to locate the repository when a user tries to
make changes.

### Somewhat automated methods

Two helper scripts exist in the `runbooks` repo which are intended to make it
easier to undo a migration, failed or otherwise.

The state of the automation for this particular set of tooling could be significantly improved.

#### First: Original file system roll-back

For undoing the original repository rename operation: [`scripts/storage_repository_restore.sh`](../../scripts/storage_repository_restore.sh)

1. Download this script to the source shard node file system: `sudo mkdir -p /var/opt/gitlab/scripts; sudo curl --silent https://gitlab.com/gitlab-com/runbooks/raw/master/scripts/storage_repository_restore.sh --output /var/opt/gitlab/scripts/storage_repository_restore.sh; sudo chmod +x /var/opt/gitlab/scripts/storage_repository_restore.sh`
2. Invoke a dry-run with: `sudo /var/opt/gitlab/scripts/storage_repository_restore.sh --dry-run=yes '@hashed/XX/XX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'` (Where the second parameter is the disk path of the project repository)
3. Review the output.
4. Invoke: `sudo /var/opt/gitlab/scripts/storage_repository_restore.sh --dry-run=no '@hashed/XX/XX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'`

#### Second: Database roll-back

A script exists in this repo for undoing the database update to the project `repository_storage` field: [`scripts/restore.sh`](../../scripts/storage_revert.rb)
1. Download this script to the source shard node file system: `sudo mkdir -p /var/opt/gitlab/scripts; sudo curl --silent https://gitlab.com/gitlab-com/runbooks/raw/master/scripts/storage_revert.rb --output /var/opt/gitlab/scripts/storage_revert.rb; sudo chmod +x /var/opt/gitlab/scripts/storage_revert.rb`
2. Make a note of the project ID.  Use it in place of `XXXXXX` below.
3. Invoke a dry-run with: `sudo gitlab-rails runner /var/opt/gitlab/scripts/storage_revert.rb --verbose --dry-run=yes --original-file-server=nfs-file01 --project=XXXXXX`
4. Review the output.
5. Invoke: `sudo gitlab-rails runner /var/opt/gitlab/scripts/storage_revert.rb --verbose --dry-run=no --original-file-server=nfs-file01 --project=XXXXXX`

#### Finally: Failed replica repository deletion

For undoing the replica repository creation operation: [`../../scripts/storage_repository_restore.sh`](../../scripts/storage_repository_restore.sh)

1. Download this script to the target shard node file system: `sudo mkdir -p /var/opt/gitlab/scripts; cd /var/opt/gitlab/scripts; sudo curl --silent https://gitlab.com/gitlab-com/runbooks/raw/master/scripts/storage_repository_delete.sh --output /var/opt/gitlab/scripts/storage_repository_delete.sh; sudo chmod +x /var/opt/gitlab/scripts/storage_repository_delete.sh`
2. Invoke a dry-run with: `sudo /var/opt/gitlab/scripts/storage_repository_delete.sh --dry-run=yes '@hashed/XX/XX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'` (Where again the second parameter is the disk path of the project repository)
3. Review the output.
4. Invoke: `sudo /var/opt/gitlab/scripts/storage_repository_delete.sh --dry-run=no '@hashed/XX/XX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'`

## General clean-up

After each project repository has finished being completely mirrored to its new storage node home, each original repository must be removed from their source storage node.

### Manual method

   - Create a list of moved repositories to delete on file-XX.
   ```bash
   # It looks like there is a scenario where there already are repo files named *+moved*.git so we don't want to
   # include them in the re-balancing. Therefore, use -ctime to filter for repo files changed within the short period of time.
   # Here, we are using -ctime as within 2 days. (Feel free to change it)
   find /var/opt/gitlab/git-data/repositories/@hashed -mindepth 2 -maxdepth 3 -ctime -2 -name *+moved*.git > files_to_remove.txt
   < files_to_remove.txt xargs du -ch | tail -n1
   ```
   - Have another SRE review the files to be removed to avoid loss of data.
   - Create GCP snapshot of disk on file-XX and include a link to the production issue in the snapshot description.
   - Take a before df to show before disk space in use `df -h /dev/sdb`
   - Remove the files `< files_to_remove.txt xargs -rn1 ionice -c 3 rm -fr`
   - Take an after df to show after disk space in use `df -h /dev/sdb`

### Somewhat automated method

A script exists in this repo
[`scripts/storage_cleanup.rb`](../../scripts/storage_cleanup.rb)

The goal of this script is to access a log file on a gitlab console node which
is expected to contain json entries describing individual project migrations,
and the storage node and disk paths to the original repositories.  This script
will iterate through this list, and use the log entry information to remotely
delete the repositories (marked `+moved`) which remain at those paths.

#### Script usage

1. Copy the script to your local workstation.  (The script *must* be ran from
your local workstation, because it will need secure shell access to both the
console node *and* the file storage nodes which contain the remaining project
repositories.)
```bash
git clone git@gitlab.com:gitlab-com/runbooks.git; cd runbooks; chmod +x scripts/storage_cleanup.rb
```
2. Confirm that the script can be ran: `scripts/storage_cleanup.rb --help`
3. Conduct a dry-run of the cleanup script.
   - Example dry-run usage: `scripts/storage_cleanup.rb --verbose --dry-run=yes`
4. For each unique storage node listed in the dry-run output, you should
perform a GCP snapshot of its larger disk.  This way any deleted repository can
be recovered, if needed. For example:
```bash
gcloud auth login
gcloud config set project gitlab-production
gcloud config set compute/region us-east1
gcloud config set compute/zone us-east1-c
gcloud compute disks list | grep file-24-stor-gprd-data
gcloud compute disks snapshot file-24-stor-gprd-data
```
5. Finally, execute the cleanup script.
 - If one is feeling particularly cautious, a single storage node can be targeted.  For example: `scripts/storage_cleanup.rb --verbose --dry-run=no --node=file-24-stor-gprd.c.gitlab-production.internal`
 - If one is feeling extra especially cautious, combine a dry-run with single node restriction: `scripts/storage_cleanup.rb --verbose --dry-run=yes --node=file-24-stor-gprd.c.gitlab-production.internal`

### Verify Information

Via the rails console, we have a few easy lookups to see where a project lives,
what its filepath is, and if it is writeable. For example:

```ruby
[ gstg ] production> project = Project.find(1234567890)
=> #<Project id:1234567890 foo/bar>
[ gstg ] production> project.repository_storage
=> "nfs-file05"
[ gstg ] production> project.disk_path
=> "@hashed/8d/23/8d23cf6c86e834a7aa6ede26ce2bb2e74903538c61bdd5d2197997ab2f72"
[ gstg ] production> project.repository_read_only
=> false
```

## Potential Outcomes

* Success - meaning both the git repo and the wiki repo will have moved to the
  new server, the old directories will have been renamed `<reponame>+moved.*`
* The repo might not move all of the data, but it's _NOT_ marked `read_only`
  * In this case, the job had detected a failure, the data can be removed from
    the `target-file-server` without harm
* The repo might move all of the data, but it _IS_ marked as `read_only`
  * Check which server GitLab thinks the storage should live on, if it's still
    the old server, simply remove the data from the `target-file-server` and
    mark the repo as writable:
    `foo = Project.find(<ID>); foo.repository_read_only=false; foo.save`

## Improvements for this script/process

* Auto log to a file without the need for `tee`
* Dynamic wait time
* Error handling
  - One example, we query all projects at the start, and then query each project id later, if the project doesn't exist that second time, the script bails
* Detect job failures so we aren't waiting unnecessarily
* https://gitlab.com/gitlab-org/gitlab-ee/issues/9563
* https://gitlab.com/gitlab-org/gitlab-ee/issues/9534
* Automate the script process with Ansible or similar. Even just having an automated script that can migrate 500GB at a time from the most used to least used gitaly node would help make this less of a chore.
* Develop some find and du commands to look for:
  - Repos larger than 20GB
  - Repos that are growing very quickly
* Ideally, the application could auto migrate repos over time.

## Gotchas

Sometimes moving a project can timeout and encounter irrecoverable errors. When
this happens the project will appear to the end user as if it is gone. On the
file system where it originally was there will be a directory appended with
`+moved-YYYMMDD-HHMMSS`. It is perfectly fine to copy this back into the
original file name and try again.

## Behind the Scenes

This is running a `git upload-pack` to determine what data needs to be
transferred to the other server.  The `target-file-server` will create a bare
repo and then data will then slowly be pushed using git to the new location.
The repo will be marked as `read_only` when the worked is queued up.



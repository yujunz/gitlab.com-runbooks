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

You may find the implementation here: https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/services/projects/update_repository_storage_service.rb#L16

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

1. Login to gitlab.com using an admin account.
1. Navigate to https://gitlab.com/profile/personal_access_tokens and generate a private token.
  - Enable the scope for `api`.
  - Set an expiration date three or four days from now.
1. Take note of the project ID. You will need it to move the project via the API. You can find it in the project page, next to the project avatar and under the project name.
1. Export your admin auth token as an environmdent variable in your shell session.
   ```bash
   export GITLAB_GPRD_ADMIN_API_PRIVATE_TOKEN=CHANGEME
   ```
1. Trigger the move using the API.  For example:
   ```bash
   export project_id=12345678
   export destination_storage_name='nfs-fileYY'
   export move_id=$(curl --silent --show-error --request POST "https://gitlab.com/api/v4/projects/${project_id}/repository_storage_moves" --data "{\"destination_storage_name\": \"${destination_storage_name}\"}" --header "Private-Token: ${GITLAB_GPRD_ADMIN_API_PRIVATE_TOKEN}" --header 'Content-Type: application/json')
   ```
  - _Note_: The parameter of `destination_storage_name` is the name of the destination gitaly shard as configured in the `git_data_dirs` options of the `gitlab.rb` file.
  - _Note_: The project will automatically be set into read-only and set back to read-write after the move.
1. To observe the status of the repository replication, use a get:
   ```bash
   curl --silent --show-error "https://gitlab.com/api/v4/projects/${project_id}/repository_storage_moves/${move_id}" --header "Private-Token: ${GITLAB_GPRD_ADMIN_API_PRIVATE_TOKEN}" --header 'Content-Type: application/json'
   ```
1. If needed, check logs for the sidekiq job in Kibana: https://log.gprd.gitlab.net/goto/35c31768d3be0137be06e562422ffba0
1. Optionally confirm the new location:
   ```bash
   curl --silent --show-error "https://gitlab.com/api/v4/projects/${project_id}" --header "Private-Token: ${GITLAB_GPRD_ADMIN_API_PRIVATE_TOKEN}" | jq -r '.repository_storage'
   ```

### Slightly automated method

A script exists in this repo:
[`scripts/storage_rebalance.rb`](../../scripts/storage_rebalance.rb)

The goal of this script is to safely and reliably replicate project git
repositories from one gitaly shard to another.

This script will select projects with the largest repositories on the given
source gitaly shard and schedule them for replication to the destination
gitaly shard.  If a minimum amount of gigabytes is given, the script will
continue to replicate repositories to the destination shard until the total
gigabytes replicated has reached the given amount.

#### How to use it

1. Clone this repository: `git clone git@gitlab.com:gitlab-com/runbooks.git`
1. Change directory into the cloned runbooks project repository: `cd runbooks`
1. Install any necessary rubies and dependencies:
   ```bash
   rbenv install $(rbenv local)
   gem install bundler
   bundle install --path=vendor/bundle
   ```
1. You will need a personal access token with the `api` scope enabled. Export
the token as an environment variable in your shell session:
   ```bash
   export GITLAB_GPRD_ADMIN_API_PRIVATE_TOKEN=CHANGEME
   ```
1. Invoke the script using the `--help` flag for usage details: `bundle exec scripts/storage_rebalance.rb --help`
1. [Create a new production change issue using the `storage_rebalancing` template](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/new?issuable_template=storage_rebalance) and follow the instructions in the issue description.
1. Invoke a dry run and record the output in the re-balancing issue.
   ```bash
   bundle exec scripts/storage_rebalance.rb nfs-fileXX nfs-fileYY --move-amount=1000 --dry-run=yes | tee scripts/logs/nfs-fileXX.migration.$(date --utc +%Y-%m-%d_%H:%M).log
   ```
1. Invoke the same command except with the `--dry-run=no` argument.

**Note:** Repository replication errors are recorded, and their log artifacts may be reviewed:
```bash
find scripts/storage_migrations -name failed*.log -exec cat {} \; | jq
```

The script will automatically skip such failed project repository replications
in subsequent invocations.  Additional projects may be skipped using the
`--skip` command line argument.

#### Failure modes

Plenty of progress has been made recently to reduce failure cases. There are still a handful of ways that a repository can fail to replicate onto the file system of another shard.

- **Checksum validation failure**
  * This means that the collective refs of the replica do not match the collective refs of the original.
- **Timeout**
  * This means that some process or `grpc` operation has taken too long, and did not complete within a pre-configured or programmatic parametric timeout.

In both of these situations, no roll-back is required, because the error is
raised by gitaly and interrupts the worker process.

## Reviewing replicated repositories

It is useful, but not required, to record details about both the original
repository and the replica repository.  Unfortunately, the existing `projects`
API does not include the `disk_path` attribute of a particular project. This
makes it a little complicated to carefully examine details of the project
repository on the file system of a gitaly shard.

1. Copy the `project_id` for a project which has completed or is undergoing
replication.
1. Open a rails console session: `ssh <username>-rails@console-01-sv-gprd.c.gitlab-production.internal`
1. Run this command: `Project.find(<project_id>)&.disk_path`
1. Copy the disk path of the project repository from the
`storage_rebalance.rb` script output of the "successful" migration.

### Install the info helper script

1. Secure shell to the source gitaly shard node system. For example: `ssh file-33-stor-gprd.c.gitlab-production.internal`
1. Download this script to the source shard node file system: `sudo mkdir -p /var/opt/gitlab/scripts; sudo curl --silent https://gitlab.com/gitlab-com/runbooks/raw/master/scripts/storage_repository_info.sh --output /var/opt/gitlab/scripts/storage_repository_info.sh; sudo chmod +x /var/opt/gitlab/scripts/storage_repository_info.sh`
1. Now exit the shell session to that shard node.
1. Repeat these steps for the destination gitaly shard system.

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

#### Failed replica repository deletion

For undoing the replica repository creation operation: [`../../scripts/storage_repository_delete.sh`](../../scripts/storage_repository_delete.sh)

1. Download this script to the target shard node file system:
   ```bash
   sudo mkdir -p /var/opt/gitlab/scripts; cd /var/opt/gitlab/scripts; sudo curl --silent https://gitlab.com/gitlab-com/runbooks/raw/master/scripts/storage_repository_delete.sh --output /var/opt/gitlab/scripts/storage_repository_delete.sh; sudo chmod +x /var/opt/gitlab/scripts/storage_repository_delete.sh
   ```
1. Invoke a dry-run with:
   ```bash
   sudo /var/opt/gitlab/scripts/storage_repository_delete.sh --dry-run=yes '@hashed/XX/XX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'` (Where again the second parameter is the disk path of the project repository)
   ```
1. Review the output.
1. Invoke:
   ```bash
   sudo /var/opt/gitlab/scripts/storage_repository_delete.sh --dry-run=no '@hashed/XX/XX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
   ```

## General clean-up

After each project repository has finished being completely mirrored to its new storage node home, each original repository must be removed from their source storage node.

### Manual method

1. Create a list of moved repositories to delete on `file-XX`:
   ```bash
   find /var/opt/gitlab/git-data/repositories/@hashed -mindepth 2 -maxdepth 3 -name *+moved*.git > files_to_remove.txt
   < files_to_remove.txt xargs du -ch | tail -n1
   ```
1. Have another SRE review the files to be removed to avoid loss of data.
1. Create GCP snapshot of disk on `file-XX` and include a link to the production issue in the snapshot description.
1. Record the current disk space usage:
   ```bash
   df -h /dev/sdb`
   ```
1. Remove the files:
   ```bash
   < files_to_remove.txt xargs -rn1 ionice -c 3 rm -fr
   ```
1. Record the recovered disk space: `df -h /dev/sdb`

### Somewhat automated method

A script exists in this repo
[`scripts/storage_cleanup.rb`](../../scripts/storage_cleanup.rb)

The goal of this script is to conduct a `find` operation on a gitaly shard
node in order to discover individual project repositories which are marked as
`+moved+`.  The script will estimate the disk space which would be freed when
ran in dry-run mode, and will re-run the find command to `rm -rf` each found
remnant git repository.

#### Clean-up script usage

1. Copy the script to your local workstation.  (The script *must* be ran from
your local workstation, because it will need secure shell access to the file
storage nodes which contain the remaining project repositories.)
1. Confirm that the script can be ran: `bundle exec scripts/storage_cleanup.rb --help`
1. Conduct a dry-run of the cleanup script:
   ```bash
   bundle exec scripts/storage_cleanup.rb file-XX-stor-gprd.c.gitlab-production.internal --verbose --scan --dry-run=yes
   ```
1. For each unique storage node listed in the dry-run output, you should
perform a GCP snapshot of its larger disk.  This way any deleted repository can
be recovered, if needed. For example:
   ```bash
   export disk_name='file-XX-stor-gprd-data'
   gcloud auth login
   gcloud config set project gitlab-production
   export zone=$(gcloud compute disks list --filter="name=('${disk_name}')" --format=json | jq -r '.[0]["zone"]' | cut -d'/' -f9)
   echo "${zone}"
   export snapshot_name=$(gcloud compute disks snapshot "${disk_name}" --zone="${zone}" --format=json | jq -r '.[0]["name"]')
   echo "${snapshot_name}"
   gcloud compute snapshots list --filter="name=('${snapshot_name}')" --format=json | jq -r '.[0]["status"]'
   ```
1. Request a review from another SRE of the output of the dry-run execution
plan of the cleanup script.
1. Finally, execute the cleanup script:
   ```bash
   bundle exec scripts/storage_cleanup.rb file-XX-stor-gprd.c.gitlab-production.internal --verbose --scan --dry-run=no
   ```

### Verify information

Via the rails console, we have a few easy lookups to see where a project lives,
what its filepath is, and if it is writeable. For example:

```ruby
[ gstg ] production> project = Project.find(12345678)
=> #<Project id:12345678 foo/bar>
[ gstg ] production> project.repository_storage
=> "nfs-file05"
[ gstg ] production> project.disk_path
=> "@hashed/4a/68/4a68b75506effac26bc7660ffb4ff46cbb11ba00ed4795c1c5f0125f256d7f6a"
[ gstg ] production> project.repository_read_only
=> false
```

## Potential outcomes

### Success

Meaning both the git repo and the wiki repo will have moved to the new server,
the old directories will have been renamed `<reponame>+moved.*`

### Failure

Typical failure modes involve a scenario wherein the original git repository
remains intact on the source shard, but there may be an inconsistent replica
repository left on the file system of the destination shard.

It is important to note that the end-user will not notice any problems with
this, so when failures like this occur, there is no reason to take any
immediate corrective action.

There is currently no mandate to delete or clean up the inconsistent replica
repository which was the subject of a failed replication process.

In order to accomplish such a task, it would be necessary to install an audit
script onto each gitaly shard, and scan the `/var/opt/gitlab/git-data/repositories/@hashed`
directory and query each and every single found disk_path in the database to
check for an invalid residence.

## Improvements for this script/process

* Automatically send logs to elasticsearch instead of using `tee`.
  - https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9474
* Automate the invocation of the `storage_rebalance.rb` script with Ansible
  or similar. Even just having an automated script that can migrate 500GB at a
  time from the most used to least used gitaly node would help make this less
  of a chore.
* Ideally, the GitLab application itself could autonomously balance git
repositories in the background.

## Behind the scenes

The `gitlab-rails` Worker which is enqueued in sidekiq to run asynchronously
is invoking a grpc method in gitaly called `ReplicateRepository` after creating
a repository directory on the destination shard file system.  If the repository
directory already exists, it invokes the grpc method in gitaly called
`FetchInternalRemote` which pulls the data from the original repository into
the replica repository.  Once this data replication has completed, the Worker
then updates the `Project.repository_storage` in the application database to
specify the name of the new shard, i.e.: `nfs-fileYY`.  The original repository
is renamed by the Worker to mark it as `+moved+`.  The project is marked
read-only in the database throughout this entire procedure.


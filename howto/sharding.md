# Managing GitLab Storage Shards (Gitaly)

## Sharding Overview

Sharding was introduced into GitLab in version 8.10 with modifications in 8.13.
The fundamentals of sharding can be found in the GitLab Documentation under
[Repository Storage Paths](https://docs.gitlab.com/ce/administration/repository_storage_paths.html).

The summary of the documentation being as such:
1. Storage targets must be defined in the `gitlab.rb` configuration file within
the `git_data_dirs` parameter.
1. Selection of targets for random new project assignment is done through the
'Application Settings' under the 'Admin Area'.

### GitLab Chef Configuration

We use chef to configure the storage shards that we have, these configuration
settings are applied via the `gitlab-base` chef role [internal link](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/roles/gitlab-base.json#L193-207).

## Moving Repositories between Shards

### Dashboards

The Gitaly Rebalancing dashboard (https://dashboards.gitlab.net/d/gitaly-rebalancing/gitaly-rebalance-dashboard?orgId=1) is designed to assist with decision making around
manual rebalancing of repositories. It is recommended that this dashboard is consulted before triggering a manual rebalance, to get an idea of which servers
are over-utilized and which ones are under-utilized.

### Overview ###

Repositories are moved by scheduling sidekiq jobs called `project_update_repository_storage` (you can check logs for it in Kibana, see job implementation in gitlab repo, etc).

### Manual Method

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


### Slightly Automated Method
A script exists in this repo
[`scripts/storage_rebalance.rb`](../scripts/storage_rebalance.rb)

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

#### How to Use it

1. Copy it to a location where the git user can access it on the console server.
   The console server might be a good location. `sudo mkdir -p /var/opt/gitlab/scripts; sudo mkdir -p /var/opt/gitlab/scripts/logs; sudo cd /var/opt/gitlab/scripts sudo curl --silent --remote-name https://gitlab.com/gitlab-com/runbooks/raw/master/scripts/storage_rebalance.rb; sudo chmod +x storage_rebalance.rb`
1. You will need a personal access token that has _API_ access using your admin
   account. This token will need to be exported as an environment variable,
   `PRIVATE_TOKEN`. `export PRIVATE_TOKEN=CHANGEME`
1. Invoke the script using the `--help` flag for usage details: `/var/opt/gitlab/scripts/storage_rebalance.rb --help` (A warning will appear because the script is not being ran with a `gitlab-rails runner`.  This is fine for now.)
1. See issue https://gitlab.com/gitlab-com/gl-infra/production/issues/664 for
   further inspiration
1. Or use this guideline below on how to conduct a production issue repo move.
   - Install the migration script on a common system (console server).
   - Dry run the migration script and look for problems.
   ```
   time gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --current-file-server=nfs-fileXX --target-file-server=nfs-fileYY --dry-run=yes --wait=10800 --move-amount=1000 2>&1 | tee "/var/opt/gitlab/scripts/logs/migration.$(date +%Y-%m-%d_%H:%M).log"
   ```
   - Execute the migration script in a tmux session on the console server during low utilization time period.
   ```
   time gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --current-file-server=nfs-fileXX --target-file-server=nfs-fileYY --dry-run false --wait 10800 --move-amount=1000 2>&1 | tee "/var/opt/gitlab/scripts/logs/migration.$(date +%Y-%m-%d_%H:%M).log"
   ```
   - Review any timed out transactions and restore/repair any repositories to their proper writable status.

#### Cleaning up

After each project repository has finished being completely mirrored to its new storage node home, each original repository must be removed from their source storage node.

##### Manual method

   - Create a list of moved repositories to delete on file-XX.
   ```
   # It looks like there is a scenario where there already are repo files named *+moved*.git so we don't want to
   # include them in the rebalancing. Therefore, use -ctime to filter for repo files changed within the short period of time.
   # Here, we are using -ctime as within 2 days. (Feel free to change it)
   find /var/opt/gitlab/git-data/repositories/@hashed -mindepth 2 -maxdepth 3 -ctime -2 -name *+moved*.git > files_to_remove.txt
   < files_to_remove.txt xargs du -ch | tail -n1
   ```
   - Have another SRE review the files to be removed to avoid loss of data.
   - Create GCP snapshot of disk on file-XX and include a link to the production issue in the snapshot description.
   - Take a before df to show before disk space in use `df -h /dev/sdb`
   - Remove the files `< files_to_remove.txt xargs -rn1 ionice -c 3 rm -fr`
   - Take an after df to show after disk space in use `df -h /dev/sdb`

##### Somewhat automated method
A script exists in this repo
[`scripts/storage_cleanup.rb`](../scripts/storage_cleanup.rb)

The goal of this script is to access a log file on a gitlab console node which
is expected to contain json entries describing individual project migrations,
and the storage node and disk paths to the original repositories.  This script
will iterate through this list, and use the log entry information to remotely
delete the repositories (marked `+moved`) which remain at those paths.

##### Script usage

1. Copy the script to your local workstation.  (The script *must* be ran from your local workstation, because it will need secure shell access to both the console node *and* the file storage nodes which contain the remaining project repositories.) `git clone git@gitlab.com:gitlab-com/runbooks.git; cd runbooks; chmod +x scripts/storage_cleanup.rb`
1. Confirm that the script can be ran: `scripts/storage_cleanup.rb --help`
1. Conduct a dry-run of the cleanup script.
   - Example dry-run usage: `scripts/storage_cleanup.rb --verbose --dry-run=yes`
1. For each unique storage node listed in the dry-run output, you should perform a GCP snapshot of its larger disk.  This way any deleted repository can be recovered, if needed. For example: `gcloud auth login; gcloud config set project gitlab-production; gcloud config set compute/region us-east1; gcloud config set compute/zone us-east1-c; gcloud compute disks list | grep file-24-stor-gprd-data;gcloud compute disks snapshot file-24-stor-gprd-data`
1. Finally, execute the cleanup script.
 - If one is feeling particularly cautious, single storage node can be targetted.  For example: `scripts/storage_cleanup.rb --verbose --dry-run=no  --node=file-24-stor-gprd.c.gitlab-production.internal`
 - If one is feeling extra especially cautious, combine a dry-run with single node restriction: `scripts/storage_cleanup.rb --verbose --dry-run=yes  --node=file-24-stor-gprd.c.gitlab-production.internal`

#### Verify Information
Via the rails console, we have a few easy lookups to see where a project lives,
what it's filepath is, and if it is writeable. For example:
```
[ gstg ] production> project = Project.find(1234567890)
=> #<Project id:1234567890 foo/bar>
[ gstg ] production> project.repository_storage
=> "nfs-file05"
[ gstg ] production> project.disk_path
=> "@hashed/8d/23/8d23cf6c86e834a7aa6ede26ce2bb2e74903538c61bdd5d2197997ab2f72"
[ gstg ] production> project.repository_read_only
=> false
```

#### Pitfalls of this
* If too many are executed at once, we'll start to drown the file server
  * this required a `renice` of processes that were driving the IO load the last
    time we induced a self inflicted performance issue
* It is _STRONGLY_ encouraged to capture the output, there is literally no other
  way to know the progress of this script
* The query will sometimes fail as it'll take too long

#### Potential Outcomes
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

#### Improvements for this script/process
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

# Managing GitLab Storage Shards

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
settings are applied via the `gitlab-base` chef role [internal link](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/roles/gitlab-base.json#L193-207).

## Moving Repositories between Shards

### Manual Method
Git repositories can me moved between shards using an administrative API command:

`curl --request PUT --header "PRIVATE-TOKEN: token_goes_here" -d repository_storage=nfs-fileXX https://gitlab.com/api/v4/projects/project_id_here`

The option of `repository_storage` is the short name configured in the `git_data_dirs`
options of the `gitlab.rb` file.  The target repository that you are electing to move is
specified by the numerical `project_id` number associated with it.

### Slightly Automated Method
A script exists in this repo
[`scripts/storage_rebalance.rb`](../scripts/storage_rebalance.rb)

The goal of this script is to select two file servers, one of which we want to
move data _OFF_, otherwise known as `current-file-server`, and one where we want
to move data _TO_, otherwise known as `target-file-server`.  We then select how
much data we'd like to move.  This script will then query all projects on that
file server, their repository size that is known in the `project statistics`
table and sort it by the project that was updated by data ascending.

#### How to Use it
1. Copy it to a location where the git user can access it on the console server
1. Utilize the `-h` flag for details on how to use it
1. See issue https://gitlab.com/gitlab-com/gl-infra/production/issues/664 for
   further inspiration

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
  * One example, we query all projects at the start, and then query each project
    id later, if the project doesn't exist that second time, the script bails
* Detect job failures so we aren't waiting unnecessarily
* https://gitlab.com/gitlab-org/gitlab-ee/issues/9563
* https://gitlab.com/gitlab-org/gitlab-ee/issues/9534

## Gotchas

Sometimes moving a project can timeout and encounter irrecoverable errors. When
this happens the project will appear to the end user as if it is gone. On the file
system where it originally was there will be a directory appended with `+moved-YYYMMDD-HHMMSS`.
It is perfectly fine to copy this back into the original file name and try again.


## Behind the Scenes

This is running a `git upload-pack` to determine what data needs to be
transferred to the other server.  The `target-file-server` will create a bare
repo and then data will then slowly be pushed using git to the new location.
The repo will be marked as `read_only` when the worked is queued up.

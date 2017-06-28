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

Git repositories can me moved between shards using an administrative API command:

`curl --request PUT --header "PRIVATE-TOKEN: token_goes_here" -d repository_storage=nfs-fileXX https://gitlab.com/api/v4/projects/project_id_here`

The option of `repository_storage` is the short name configured in the `git_data_dirs`
options of the `gitlab.rb` file.  The target repository that you are electing to move is
specified by the numerical `project_id` number associated with it.

## Gotchas

Sometimes moving a project can timeout and encounter irrecoverable errors. When
this happens the project will appear to the end user as if it is gone. On the file
system where it originally was there will be a directory appended with "-MOVED-YYYMMDD-HHMMSS".
It is perfectly fine to copy this back into the original file name and try again.


## Behind the Scenes

What's happening behind the scenes when the API command is issued is a simple 
rsync from one directory structure path to another. The rsync is limited with a 
nice command so that it performs in the background and doesn't over-consume
resources on the API host.

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

## Project repository storage re-balancing

The how-to instructional documentation for re-balancing git project
repositories between `gitaly` storage shard node file systems is here:

https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/gitaly/storage-rebalancing.md

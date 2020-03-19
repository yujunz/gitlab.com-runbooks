# Missing Repositories

A repository may appear missing, but it does not mean it was erased completely.

## Symptoms

* A project page showing "No repository" and prompts for "Create empty repository"

## Preparations

In a Rails console, grab some information about the project, keep it open as it could be needed later:

```
> project = Project.find_by_full_path('gitlab/top-secret')
=> #<Project id:1 gitlab/top-secret>
> project.repository_storage
=> "nfs-file15" # Which shard we think the repo is under
> project.repository.path
=> "/var/opt/gitlab/git-data-file15/repositories/gitlab/top-secret.git"
> # This path on shard 15 is actually /var/opt/gitlab/git-data/repositories/gitlab/top-secret.git
```

## Troubleshooting

### Does it actually exists on disk?

Log in to the shard we think the repository is under, run

```
$ sudo ls /var/opt/gitlab/git-data/repositories/gitlab/top-secret.git
```

If you see a repository present, then it could be a caching problem which can happen for various reasons, see how to clear it below.


### Clearing repository cache

In a Rails console run

```
> Project.find_by_full_path('gitlab/top-secret').repository.expire_all_method_caches
```

Check the project page again.

### Check the namespace for the missing repository across all shard

A failed group move operation can end the project in an inconsistent state. Say we were moving from "gitlab" to "gitlab-new".

In a local workstation, run

```
$ knife ssh 'roles:gprd-base-stor-nfs' 'sudo ls -hal /var/opt/gitlab/git-data/repositories/gitlab 2>/dev/null'
$ knife ssh 'roles:gprd-base-stor-nfs' 'sudo ls -hal /var/opt/gitlab/git-data/repositories/gitlab-new 2>/dev/null'
```

You can find the project name present in a different shard and/or under a different namespace.

* Different namespace: Move the repository and its wiki to the current namespace of the project (i.e. the one the project is associated with currently)
* Different shard: In a Rails console, update the `repository_storage` attribute of the project to the shard holding the repository
```
> Project.find_by_full_path('gitlab/top-secret').update_attribute(:repository_storage, 'nfs-file10')
```

Clear the cache per the instructions above, then check the project page again.

### Does not exist in any of the shards?

#### Check if it exist in a Geo replica

_TODO: Add instruction_

#### Check if it exists in a restored snapshot of a shard disk

_TODO: Add instruction_

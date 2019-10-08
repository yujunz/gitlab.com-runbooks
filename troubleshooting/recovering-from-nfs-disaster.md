# Recovering from NFS disaster

## Symptoms

Existing projects are reporting a missing repository on the web UI, or you're
seeing this message when interacting with a remote repo using git:

```
GitLab: A repository for this project does not exist yet.
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
```

## Resolution

Run the script in scripts/flush_exists_cache.rb on a production node, there may be
a load increase on the primary DB, it should fade away in a few minutes.

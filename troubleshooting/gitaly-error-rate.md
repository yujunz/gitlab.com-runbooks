# Gitaly error rate is too high

## First and foremost

*Don't Panic*

## Symptoms

* Message in prometheus-alerts _Gitaly error rate is too high_

## 1. Ensure that the same version of Gitaly is running across the entire fleet

- Visit the **[Gitaly Version Tracker grafana dashboard](https://dashboards.gitlab.net/dashboard/db/gitaly-version-tracker?orgId=1)**.
- Ensure the the entire fleet is running the **same major and minor versions** of Gitaly. The build time tag on the version should be ignored until [gitlab-org/gitaly#388](https://gitlab.com/gitlab-org/gitaly/issues/388) is resolved.
- The only time that the fleet should be runnnig mixed versions of Gitaly is during the deployment process
  - During a deploy, it is important that the storage tier (NFS servers) are upgraded **before** the front-end tier
  - Otherwise, it's likely that front-end servers will make requests to the NFS servers that they are unable to fulfill.


## 2. Identify the problematic instance

- Go to https://dashboards.gitlab.net/dashboard/db/gitaly?panelId=2&fullscreen and
identify the instance with a high error rate.
- ssh into that instance and check the log for its Gitaly server for post-mortem:

```
sudo less /var/log/gitlab/gitaly/current
```

## 3. Disable the Gitaly operation causing trouble

- Go to https://dashboards.gitlab.net/dashboard/db/gitaly-features?orgId=1 and identify the feature with a high error rate.
- Disable the relevant feature flag by running `!feature-set <flag_name> false`
on Slack's #production channel. The mapping of flag names to gRPC calls is as follows:


| Flag name             | gRPC call             |
|-----------------------|-----------------------|
| gitaly_root_ref       | FindDefaultBranchName |
| gitaly_branch_names   | FindAllBranchNames    |
| gitaly_tag_names      | FindAllTagNames       |
| gitaly_local_branches | FindLocalBranches     |
| gitaly_is_ancestor    | CommitIsAncestor      |
| gitaly_find_ref_name  | FindRefName           |

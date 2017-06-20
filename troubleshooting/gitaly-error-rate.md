# Gitaly error rate is too high

## First and foremost

*Don't Panic*

## Symptoms

* Message in prometheus-alerts _Gitaly error rate is too high_

## 1. Identify the problematic instance

- Go to https://performance.gitlab.net/dashboard/db/gitaly?panelId=2&fullscreen and
identify the instance with a high error rate.
- ssh into that instance and check the log for its Gitaly server for post-mortem:

```
sudo less /var/log/gitlab/gitaly/current
```

## 2. Disable the Gitaly operation causing trouble

- Go to https://performance.gitlab.net/dashboard/db/gitaly-features?orgId=1 and identify the feature with a high error rate.
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


- If that doesn't solve the issue you can disable Gitaly entirely by updating
the relevant role(s) on chef-repo and changing the Gitaly override to
`enable: false` (under `override_attributes -> omnibus-gitlab -> gitlab_rb -> gitaly`)

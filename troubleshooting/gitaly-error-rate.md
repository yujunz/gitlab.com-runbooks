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
- Update the relevant role for the problematic instance on chef-repo and remove the environment variable for the relevant operation (under `default_attributes -> omnibus-gitlab -> gitlab_rb -> gitlab-rails -> env`). The mapping of environment variables to gRPC calls is as follows:


| Env variable        | gRPC call             |
|---------------------|-----------------------|
| GITALY_ROOT_REF     | FindDefaultBranchName |
| GITALY_BRANCH_NAMES | FindAllBranchNames    |
| GITALY_TAG_NAMES    | FindAllTagNames       |


- If that doesn't solve the issue you can disable Gitaly entirely by changing the Gitaly override to `enable: false` (under `override_attributes -> omnibus-gitlab -> gitlab_rb -> gitaly`)

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

## 2. Disable Gitaly

- Update the relevant role for the problematic instance on chef-repo and change the gitaly override to `enable: false` (under override_attributes -> omnibus-gitlab -> gitlab_rb -> gitaly)

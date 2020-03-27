# Gitaly error rate is too high

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

## 3. Drill down

The Prometheus alert should be specific to one Gitaly shard.

The following sections contain some common causes, and steps to diagnose, of
elevated Gitaly shard error rates.

### Errors originating from one project

Are the errors associated with only a few projects? Check [this pie
chart](https://log.gprd.gitlab.net/app/kibana#/visualize/edit/c46c1460-7030-11ea-8617-2347010d3aab)
and filter down to the relevant instance.

What is the origin of the Gitaly requests? Check [this pie
chart](https://log.gprd.gitlab.net/app/kibana#/visualize/edit/211743f0-7032-11ea-8617-2347010d3aab)
and filter down to the relevant paths (`/namespace/project`).

If there are a lot of requests to RawController:

- Using your admin account, take a look at the requested paths.
- While the RawController is of course a legitimate endpoint that we offer, it
  can be quite expensive to serve, and we don't expect a high request rate to it
  under common use.
- Consider taking the relevant project private and/or blocking the owner and
  engaging support to contact them. Engage support to contact the user after
  this.
- If abuse is suspected (e.g. if the repository contains copyrighted media
  files) then engage the abuse team.

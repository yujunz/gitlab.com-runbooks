# Upgrades and Rollbacks of Application Code

# Overview

Upgrades and rollbacks are normally handled by the [delivery team](ttps://about.gitlab.com/handbook/engineering/infrastructure/team/delivery/)
at GitLab. In normal circumstances upgrading the application code happens Monday
through Friday when the Delivery team is available for support. In extraordinary
situations it might be necessary to deploy or rollback on a weekend. In these
cases the MOC should be paged as it may significantly impact GitLab.com.


## Application Upgrade

Application upgrade is triggered from GitLab Chatops. For more information about
how upgrade works see the
[release documentation for upgrade](https://gitlab.com/gitlab-org/release/docs/blob/master/general/deploy/gitlab-com-deployer.md#creating-a-new-deployment-for-upgrading-gitlab).


## Application Rollback

Application rollback is triggered from GitLab Chatops. For more information
about how rollback works see the
[release documentation for rollback](https://gitlab.com/gitlab-org/release/docs/blob/master/general/deploy/gitlab-com-deployer.md#creating-a-new-deployment-for-rolling-back-gitlab).

**Before rolling back the application on GitLab.com the following steps must be
performed**

- [ ] Ensure there is either a ~S1 / ~S2 issue or a google doc in the case that
  GitLab.com is unavailable
- [ ] Page the IMOC to let them know that a rollback is about to happen
```
/pd-moc We are initiating a rollback of GitLab.com, for more information see <Issue or doc link>
```
- [ ] Page the DBRE oncall to review database impacts of rollback
```
/pd-db We are initiating a rollback of GitLab.com, for more information see <Issue or doc link>
```
- [ ] The DBRE should review
  [the db considerations for rollback](https://gitlab.com/gitlab-org/release/docs/blob/master/general/deploy/gitlab-com-deployer.md#creating-a-new-deployment-for-rolling-back-gitlab#rollback-considerations-for-database-migrations)
  If the oncall DBRE is unavailable or unable to review the database impact of rollback, ensure that
  the IMOC has signed off on the rollback.
- [ ] Work with the delivery team to initiate the rollback using GitLab Chatops.
  For more information see the
  [release documentation for rollback](https://gitlab.com/gitlab-org/release/docs/blob/master/general/deploy/gitlab-com-deployer.md#creating-a-new-deployment-for-rolling-back-gitlab).

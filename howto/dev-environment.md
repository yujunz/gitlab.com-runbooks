# GitLab dev environment

We have a dev environment which is based in GitLab CE

Every morning at 7:20AM UTC a new nightly package is built and deployed into it with the latest version from the master branch.

## What is this for?

To make sure that GitLab CE keeps working ok, and to have a shorter iteration cycle when developing new CE features.

## Getting access to it

You have to be a GitLab employee to have access to it.

## How to

### Figure out the diff of deployed versions

* ssh into the host
* turn into root
* run `ls -latr /var/opt/gitlab/gitlab-rails/upgrade-status`
* you will get an ouput like this:
```
-rw------- 1 root root    2 Jun 27 07:17 db-migrate-6acdf1f
-rw------- 1 root root    2 Jun 28 07:24 db-migrate-c9a4626
-rw------- 1 root root    2 Jun 29 07:23 db-migrate-ebe21ac
```
* the final part of each file is the commit hash, get 2 of those like `c9a4626..ebe21ac`
* run `git log --oneline c9a4626..ebe21ac` to get the list of commits that got in.

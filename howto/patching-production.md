# Hot patching production

This howto is for deploying a patch or hotpatch to the production servers
outside the normal deploy cycle. This should only be done for critical fixes or
in cases where there is an outage and a change needs to be rolled out quickly
to restore access to the site.

## Submitting a patch

This is step that has to be done by the proposing team.

* Create a working branch in gitlab-ee from the current version running on
  production (visit https://gitlab.com/help to find out what this is).
  * For example, you can do `git checkout -b patch/my-fix v10.7.0-rc4-ee` if you want
    to derive your branch from `10.7.0 RC4` version based on the tag.
* Make your code changes
  * You can cherry-pick commits from CE / EE.
  * In that case remove changes to specs before generating the patch.
* Run the command `git --no-pager diff --color=never v10.7.0-rc4-ee.. -- app lib ee/app ee/lib > path/to/patch.patch`
  * **Note**: this is an example - if you have changed non-spec files in other
    directories, be sure to include those 
* Clone or Update the repo [post deployment patches][pdp]
* Create one MR for the correct version of the application following [post
  deployment patches][pdp-readme] README instructions.
  * Be sure to provide chef roles for prod, pre-prod and staging environments.
    If you don't know which should they be, just ask in the #production channel
* Submit the patch for review to someone from the production team and someone
  from the development team to sign off the changes.
* Create an issue to apply the patch in the infrastructure issue tracker, label
  it as `~change` and `~"on call"`

## Applying a hot patch to production

This step has to be done by someone with production and knife access,
preferably by the current on-call for full awareness.

* Get or update [gitlab patcher][gp]
* Clone or update [post deployment patches][pdp]
* Run `gitlab-patcher <version> <environment>` to test a dry run, watch for
  possible errors.
* Attach the output of the dry run to the patching issue (or share it somehow,
  depending on production being up)
* Get approval to apply the patch from escalation
* Run `gitlab-patcher -mode patch <version> <environment>`

## Rolling back a patch

Using the previous example, just use the rollback mode of [gitlab patcher][gp]

`gitlab-patcher -mode rollback <version> <environment>`



# Old manual (deprecated) method

This part of the runbook is kept as a sample of the way of performing a
hotpatch manually in case the automated tool fails.

* Create or find the issue for the hot patch on the infrastructure board, if
  one does not already exist [open a new
  one](https://gitlab.com/gitlab-com/infrastructure/issues/new).
* Ensure that on the issue the following criteria are met, if they are not
  comment on the issue explaining why:
    * Reason for the patch including links to related issues.
    * Customer impact, what pain will the customer be in without applying the
      patch.
    * Timeline for fixing the issue with a build in the normal deploy cycle.
    * A patch file including what servers the patch should be scoped to in the
      production fleet.
* If possible, see if the issue can be reproduced on https://staging.gitlab.com
* For production patches you should do your best to adhere to a 2-prod-engineer
  rule, open a zoom meeting during the process.
* Apply the patch on staging, confirm that the patch has been applied.
* Apply the patch on production, confirm that the patch has been applied.


## Applying the patch

The following can be used as a guide for applying patches to staging and production.

**Do not run the commands below unless you fully understand what they do.**

```
# Set this to the role you are appling to
# For example role=gitlab-base-fe-web for
# web fleet.
role=ROLE_TO_APPLY
url=URL_OF_PATCH_FILE
dir=DIRECTORY_FOR_PATCH
patch="/tmp/hotpatch-$(date +'%Y-%m-%d')"
# Download the patch file to the servers in the fleet
bundle exec knife ssh -C 1 -a ipaddress "roles:$role" "curl -o $patch $url"

# Confirm that it has been transferred
bundle exec knife ssh -C 1 -a ipaddress "roles:$role" "md5sum $patch"

# Dry run the patch
bundle exec knife ssh -C 1 -a ipaddress "roles:$role" "cd $dir && sudo patch -p1 --dry-run < $patch"

# Apply the patch
bundle exec knife ssh -C 1 -a ipaddress "roles:$role" "cd $dir && sudo patch -p1 < $patch"

# Rollback the patch
bundle exec knife ssh -C 1 -a ipaddress "roles:$role" "cd $dir && sudo patch -R < $patch"

# For updates to rails, HUP unicorn
bundle exec knife ssh -C 1 -a ipaddress "roles:$role" "sudo gitlab-ctl hup unicorn"
```


[pdp]: https://dev.gitlab.org/gitlab/post-deployment-patches
[pdp-readme]: https://dev.gitlab.org/gitlab/post-deployment-patches/tree/master/README.md
[gp]: https://gitlab.com/gl-infra/gitlab-patcher

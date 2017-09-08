# Summary
This howto is for deploying
a patch or hotpatch to the production servers outside the
normal deploy cycle. This should only be done for critical fixes
or in cases where there is an outage and a change needs to be rolled
out quickly to restore access to the site.


* Create or find the issue for the hot patch on the infrastructure board,
if one does not already exist [open a new one](https://gitlab.com/gitlab-com/infrastructure/issues/new).
* Ensure that on the issue the following criteria are met, if they are not comment
on the issue explaining why:
    * Reason for the patch including links to related issues.
    * Customer impact, what pain will the customer be in without applying the patch.
    * Timeline for fixing the issue with a build in the normal deploy cycle.
    * A patch file including what servers the patch should be scoped to in the production fleet.
* If possible, see if the issue can be reproduced on https://staging.gitlab.com
* For production patches you should do your best to adhere to a 2-prod-engineer rule, open a zoom meeting during the process.
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

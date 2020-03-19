# Removing kernels from fleet

## First and foremost

*Don't Panic*

## How do I

### Remove unlucky 4.13 kernel from all boxes that has specific chef role

Issue the following command from the chef repo:

`bundle exec knife ssh -a ipaddress 'roles:ROLE_HERE' "dpkg-query --show 'linux-*' | awk '/4\.13/ {print \$1}' | xargs -r sudo apt-get -yqq purge"`

Notes:
 - escape the dot in kernel version for stricter match
 - escape `$1` in awk so that remote bash doesn't assume $1 is its first argument
 - be careful if you adapt this command to remove 4.11 kernels for some reason,
   as those are installed in these hacky recipes for
   [azure](https://gitlab.com/gitlab-cookbooks/gitlab-server/blob/master/recipes/hack_kernel_version.rb) and
   [gcp](https://gitlab.com/gitlab-cookbooks/gitlab-server/blob/master/recipes/hack_kernel_version_gprd.rb)
   respectively.

Issues:
 - https://gitlab.com/gitlab-com/infrastructure/issues/4294
 - https://gitlab.com/gitlab-com/migration/issues/386

This was deliberately not made into chef cookbook because packer is how we should do it.

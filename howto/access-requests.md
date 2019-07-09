# Access Requests

## Add or verify data bag
1. Check ssh key
1. Check unix groups
1. knife data bag from file users <user>.json

## Chef Access
```
# on chef.gitlab.com
chef-server-ctl user-create <username> <first> <last> <email> $(openssl rand -hex 20)
# copy the output into <username>.pem and drop it in their home directory on deploy
chef-server-ctl org-user-add gitlab <username>
```

## COG Access
1. User talks to @marvin
1. Admin adds user (keep in mind slack name may be different from unix or email name)
1. !group-member-add <group> <user>

## Ops Instance Access
Generally when developers ask for access to the ops instance, we are concerned
with chatops access, which requires developer on `gitlab-com` group.
If access to any other groups are needed, please clarify with the requester.
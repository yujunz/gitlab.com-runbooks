#Access Requests

## Add or verify data bag
1. Check ssh key
1. Check unix groups
1. knife data bag from file users <user>.json

## VPN Access
https://gitlab.com/gitlab-com/runbooks/blob/master/howto/vpn-access.md
https://gitlab.com/gitlab-cookbooks/gitlab_openvpn#how-to-create-a-client-certificate
1. To grant someone external access to the vpn you will first need to add their user to the vpn server.
1. Create a databag for the user and ensure that they are in the vpn group. Submit an MR for the update (example MR.
1. After the user is created ssh to the vpn server and run /usr/local/bin/vpn-setup add <username>
1. Accept all of the defaults. When finished this will display a QR code and generate an .ovpn profile in your home directory.
1. Take a screenshot of the QR code and copy the .ovpn profile to your workstation.
1. Create a folder on google drive that contains the QR code and the .ovpn profile, be sure that you delete the screenshot and the profile from the vpn server and locally after you do this.
1. Share the folder with the user and update the issue.

##Chef Access
```
# on chef.gitlab.com
chef-server-ctl user-create <username> <first> <last> <email> $(openssl rand -hex 20)
# copy the output into <username>.pem and drop it in their home directory on deploy
chef-server-ctl org-user-add gitlab <username>
```

##COG Access
1. User talks to @marvin
1. Admin adds user (keep in mind slack name may be different from unix or email name)
1. !group-member-add <group> <user>

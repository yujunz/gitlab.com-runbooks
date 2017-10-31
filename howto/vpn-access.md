# Summary

Until we have a generalized VPN solution there may be cases where
we need to grant vpn access to gitlab team members who are not in
the production team.

## For non-production engineers

* Submit an issue to the infrastructure issue tracker to request access using the `production_access` template.
* In the issue include the reason for why it is being requested.
* A production engineer will update the issue and share a google doc folder containing a QR code and an `.ovpn` profile.
* Scan the authenticator code using the google authenticator app.
* Load the profile into your openvpn client.
* Connect to the vpn using your username and the google authenticator code as a password.

## For production engineers

* To grant someone external access to the vpn you will first need to add their user to the vpn server.
* Create a databag for the user and ensure that they are in the `vpn` group. Submit an MR for the update ([example MR](https://dev.gitlab.org/cookbooks/chef-repo/merge_requests/1248).
* After the user is created ssh to the vpn server and run `/usr/local/bin/vpn-setup add <username>`
* Accept all of the defaults. When finished this will display a QR code and generate an `.ovpn` profile in your home directory.
* Take a screenshot of the QR code and copy the `.ovpn` profile to your workstation.
* Create a folder on google drive that contains the QR code and the `.ovpn` profile, be sure that you delete the screenshot and the profile from the vpn server and locally after you do this.
* Share the folder with the user and update the issue.

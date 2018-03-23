# Summary

Until we have a generalized VPN solution there may be cases where
we need to grant vpn access to gitlab team members who are not in
the production team.

## Instructions for users requesting access

* Submit an issue to the infrastructure issue tracker to request access using the `production_access` template.
* In the issue include the reason for why it is being requested.
* A production engineer will update the issue and share a google doc folder containing a QR code and an `.ovpn` profile.
* Scan the authenticator code using the google authenticator app.
* Load the profile into your [openvpn client](https://openvpn.net/index.php/access-server/section-faq-openvpn-as/client-configuration.html).
* Connect to the vpn using your username and the google authenticator code as a password.

### Testing
You can test that you are successfully connected to the VPN by:
1. Before connecting to the VPN, check your IP address. You can do this by typing `what's my ip` in either `duckduckgo.com` or `google.com`.
1. Connect to the VPN
1. Repeat the first step, if the IP addresses are different, you are successfully connected to the VPN.

### Troubleshooting

* You may want to using [viscosity](https://www.sparklabs.com/viscosity/) which has been reported to work better than [tunnelblick](https://tunnelblick.net/) on OSX
* If you are using tunnelblick on OSX sometimes (frequently, actually) re-connections will fail, to work around this you can drop the routes with the following script
```
#!/bin/bash
echo -n "Removing all routes"
while [[ -n $(sudo route -n flush 2>/dev/null) ]]; do
    echo -n "."
    sleep .1
done
echo ""
echo "Restarting wifi"
sudo ifconfig en0 down
sudo ifconfig en0 up
```

## For production engineers

* To grant someone external access to the vpn you will first need to add their user to the vpn server.
* Create a databag for the user and ensure that they are in the `vpn` group. Submit an MR for the update ([example MR](https://dev.gitlab.org/cookbooks/chef-repo/merge_requests/1248).
* After the user is created ssh to the vpn server and run `/usr/local/bin/vpn-setup add <username>`
* Accept all of the defaults. When finished this will display a QR code and generate an `.ovpn` profile in your home directory.
* Take a screenshot of the QR code and copy the `.ovpn` profile to your workstation.
* Create a folder on google drive that contains the QR code and the `.ovpn` profile, be sure that you delete the screenshot and the profile from the vpn server and locally after you do this.
* Share the folder with the user and update the issue.

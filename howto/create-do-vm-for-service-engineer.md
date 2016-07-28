# Create DO VM for Service Engineer

Occasionally a service engineer will put in an issue on the [infrastructure tracker](https://gitlab.com/gitlab-com/infrastructure/issues) for a Digital Ocean Droplet for testing purposes. These are the steps necessary to create said VM.

The request from the team member should include a posix username, the DO datacenter they want it in, the size requested, and an SSH key for their use.

1. Create VM in the [Digital Ocean control panel](https://cloud.digitalocean.com/droplets) and name it after the requester, e.g. `alex-hanselka`.
1. Once the VM is created, log in and put the requester's SSH key into /root/.ssh/authorized_keys. Also place your own key (if it isn't there), [John's](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/data_bags/users/jjn.json#L4), [Alex's](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/data_bags/users/ahanselka.json#L4), [Pablo's](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/data_bags/users/pcarranza.json#L4), and [Jeroen's](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/data_bags/users/jeroen.json#L4).
1. Create a new user with the requester's desired posix username and put the requester's key in `/home/<username>/.ssh/authorized_keys`. Be sure to chown `.ssh/` and `.ssh/authorized_keys` to be owned by the correct user.
1. Add user to sudoers by running `usermod -a -G sudo <username>`
1. Create a [DNS record](https://console.aws.amazon.com/route53/home?region=eu-central-1#resource-record-sets:Z29MRIL9NUDAU8) in the gitlap.com zone with the same name as the server, e.g. `alex-hanselka.gitlap.com`, that points to the proper IP address.
1. Reply to the requester's issue with the IP address and DNS name of the new server. Be sure to remind them to keep the server patched and up to date!
1. Close the issue!

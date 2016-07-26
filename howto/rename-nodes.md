# Renaming Nodes

Renaming a node after it is already in Chef is a multi-step process to ensure that Chef doesn't know about the node and the node itself doesn't have remnants of its previous Chef configuration.

## Steps to Rename

1. Remove the node from Chef with knife. `knife node delete example.gitlab.com`
1. Remove /etc/chef/client.pem from the node. This must happen or Chef will get an error when trying to bootstrap the node.
1. Change the hostname on the node itself. On Ubuntu, you would update the hostname with `hostname new-hostname.gitlab.com` and edit /etc/hostname with the same name.
1. **Ensure** that `hostname -f` returns expected hostname. Chef can be very touchy about DNS and hostname changes and you really want to get this done correctly the first time.
1. Add/Change the DNS record associated with the node on AWS.
1. Bootstrap the node with Chef.
```
knife bootstrap 12.34.56.78 --node-name example.gitlap.com --sudo -x username
```
1. Move the old node info to the new name in the [chef-repo](https://dev.gitlab.org/cookbooks/chef-repo/tree/master/nodes). Be certain you also update the "name" attribute and not just copy the file to a new name.
1. Add the node to any secrets it needs to access to. `bundle exec rake 'add_node_secrets[example.gitlap.com, syslog-client]'`
1. Run chef-client on the newly renamed node to ensure success. 


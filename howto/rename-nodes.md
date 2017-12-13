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

## Troubleshooting

If the node is keeping the same name, you may have an empty node as a result. You can tell that this is the case when you run `chef-client` on the node and get an empty run list error.

To fix this you should be checking the node in chef with `knife node show <nodename>` and if it's actually empty, just load it from the chef file with `knife node from file nodes/<nodename>`

You may get secrets problem as you run chef-client, to fix this:

1. Identify which vault is failing by looking at the error, for example:
```
ChefVault::Exceptions::SecretDecryption
---------------------------------------
syslog_client/_default is encrypted for you, but your private key failed to decrypt the contents.  (if you regenerated your client key, have an administrator of the vault run 'knife vault refresh')
```
The vault here is **syslog_client** and the vault item is **_default**

1. wipe the old node registration in the chef vault file by editing it with `knife data bag edit syslog_client _default_keys`, look for the node name 2 times and delete the lines.
1. add the node to the vault again by running `bundle exec rake 'fast_add_node_vault[<node_name>,<vault_name>,<vault item>,true]'`
1. run chef client on the node again, rinse and repeat.

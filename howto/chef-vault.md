# Chef Vault Basics
[Chef vault](https://github.com/chef-cookbooks/chef-vault) has alot of information
but sometimes, not everything is as it seems. 

In general, `vaults` are data bag items which have been encrypted. 



Given vault `public-grafana`

    ```
    ~ knife vault show public-grafana
    _default
    ```

It contains one item: `_default` which can be viewed like this:

    ```
    ~ knife vault show public-grafana _default
    grafana:
      api_key:     super-secret-key 
      external_url: http://random-url.net
    ```

Because this is in reality a data bag, we can also look at the encrypted
values:

    ```
    ~ knife data bagshow public-grafana _default
		grafana:
			auth_tag:       GwOf7d7uDTEY0xkz9/XDyg==

			cipher:         aes-256-gcm
			encrypted_data: LOTS-OF-LETTERS

			version:        3
		id:      _default
    ```

You can see the keys in clear text, but not the values.

Digging a bit further, we can see how the access is configured:

    ```
    ~ knife data bagshow public-grafana
    _default
    _default_keys
    ```

Vault access is granted either to a user, a role or a client. 
Who has access can be seen by checking the data bag item with 
the same name, with `_key` appended:

    ```
    ~ knife data bagshow public-grafana _default_keys
    "admins": [
      "admin1",
      "admin2"
    ],
    "clients": [
      "server1.example.com"
    ],
    "admin1":"key-for-admin1-on-this-vault",
    "admin2":"key-for-admin2-on-this-vault",
    "server1":"key-for-server1-on-this-vault"
    ```

To grant access to a vault to a user, node, role take a look at the `rake`
task in the chef-repo with `rake -T`.

# Caveats when using `Gitlab::Vault`

Using the `Gitlab::Vault` to access secrets, may lead to confusion since
it masks what it is [actually doing](https://gitlab.com/gitlab-cookbooks/gitlab-vault/blob/master/libraries/vault.rb).

## Mixing

By accessing items like this:

    ```
    unencrypted_secrets = GitLab::Vault.get(node, 'encrypted_secrets')
    ```

we are actually mixing the `unencrypted_secrets` into the `node` object.
This means when we access attributes such as:

    ```
    node['server']['password']
    ```

the value may not actually be on the node, but be mixed in if the 
vault contains that path. (ask @jtevnan) for an nice example from the 
omnibus-cookbook.

## Vault Name

The vault name does not correspond to the key you are passing.

E.g.

    ```
    unencrypted_secrets = GitLab::Vault.get(node, 'encrypted_secrets')
    ```

Will not look for the vault named `encrypted_secrets`, but instead will look into the node's
attributes for the vaule of:

    ```
    node['encrypted_secrets']['chef_vault']
    ```

to determine which vault should be used. If this is missing, then only the node's
original values are returned. This is done transparently, so it may be 
hard to debug where values are coming from.

## Vault item Name

Similar to the maner in which the Vault is determined, the vault item can
also be configured via

    ```
    node['encrypted_secrets']['chef_vault_item']
    ```

This is not used as far as I can tell, so the default is used.
This means the chef environment configured for the node is used to
determine the vault item. At the moment all our nodes are in the
default environment (`_default`) which may explain why all the examples
above have the syntax:

    ```
    ~ knife vault show public-grafana _default
    ```

# Retrieving old Chef Vault values

If someone makes a change in an encrypted data bag, you may need to restore
the old value. For example, if the public key of GitLab Pages is changed
without updating the private key, you may need to retrieve the old value.

Fortunately, the chef-repo directory contains version-controlled encrypted
data in the data_bags directory. We can use use this to our advantage.

## How to retrieve old data

For example, let's say you want to see the data at commit
a8a60325c16ceabf5ed50d5b241fa470c478b7bf. Here's the quick playbook:

1. Check out the version of chef-repo that you want:

    ```
    git checkout a8a60325c16ceabf5ed50d5b241fa470c478b7bf
    ```

1. Upload all the data bags to your LOCAL chef installation.
    **BE SURE TO INCLUDE THE -z OPTION TO OPERATE IN LOCAL MODE**:

    ```
    knife data bag from file -a -z
    ```

1. Retrieve the data via `chef vault`. Note the -z option again:

    ```
    knife vault show <role> <values> -z
    ```

    For example:

    ```
    knife vault show gitlab-cluster-base _default -z
    ```

## Verifying SSL public/private keys

Once you have the public and private keys, you can verify that they match:

    ```
    openssl x509 -noout -modulus -in certificate.crt | openssl md5
    openssl rsa -noout -modulus -in privateKey.key | openssl md5
    ```

# Chef secrets using GKMS

In general, gkms secrets replace chef vaults, these are data bag items which have been encrypted. The chef vault conventions remain the same, an `<vault> <item>`.

## Using gkms secrets in cookbooks

There are multiple patterns for this unfortunately, see other cookbooks for
examples if you are starting from scratch. What you probably want to do is
define some secrets and merge them into node attributes. Here is an example
for using gkms secrets, assuming you want them for some `<cookbook>` in the
`gprd` environment.


```
secrets_hash = node['<cookbook>']['secrets']
secrets = get_secrets(secrets_hash['backend'], secrets_hash['path'], secrets_hash['key'])

[
  Chef::Mixin::DeepMerge.deep_merge(secrets['<cookbook>'],
node.default['<cookbook>']),
  Chef::Mixin::DeepMerge.deep_merge(secrets['<cookbook>'] || {}, node.default['<cookbook>'])
]
```

To make this work you will need to set some node attributes so the cookbook can
find the secrets:

```
default['<cookbook>']['secrets']['backend'] = 'gkms'
default['<cookbook>']['secrets']['path'] = {
    'path' => 'gitlab-gprd-secrets/<cookbook>',
    'item' => 'gprd.env',
}
default['<cookbook>']['secrets']['key'] = {
    'ring' => 'gitlab-secrets',
    'key' => 'gprd'
}
```

## Conventions

These are pretty important for the sane management of secrets across many
different environments.

* Always make the `item` the same as the environment name, for example: `gprd`,
  `gstg`, `ops`, etc.
* The bucket name (first part of the `path`) should always be
  `gitlab-<env>-secrets`
* The key ring name should be `gitlab-secrets`, if you are creating a new
  project in gcp please use that name.
* The key name should be the same as the environment, like the item.

## Managing gkms secrets

There are some helper scripts in `chef-repo/bin` to aid with the encrypting and
decrypting of secrets.  To create a new gkms vault in the `gstg` environment
for the `gitlab-elk` cookbook, for example:

```
./bin/gkms-vault-create gitlab-elk gstg
```

To show secrets for the same vault

```
./bin/gkms-vault-show gitlab-elk gstg
```

Note: you will need [gcloud setup](gcloud-cli.md) and access to the appropriate project.

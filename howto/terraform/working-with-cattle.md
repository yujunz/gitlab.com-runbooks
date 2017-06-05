# Working with cattle

Our cattle fleet (web, git, sidekiq and so on) are easily identifiable in the `main.tf` file because of the use of the `count` parameter. This specifies how many nodes Terraform should manage for that particular module. Everything that doesn't have a `count` in the module definition should be considered a pet or a snowflake.

Take the following excerpt for example:

```
module "virtual-machines-web" {
  count               = 5
  source              = "virtual-machines/web"
  location            = "${var.location}"
  resource_group_name = "${module.subnet-web.resource_group_name}"
  subnet_id           = "${module.subnet-web.subnet_id}"
  first_user_username = "${var.first_user_username}"
  first_user_password = "${var.first_user_password}"
  chef_repo_dir       = "${var.chef_repo_dir}"
  chef_vaults         = "syslog-client gitlab-cluster-base"
  gitlab_com_zone_id  = "${var.gitlab_com_zone_id}"
}
```

This is the definition of the web front-end fleet at the time of this writing. You see that `count` is set to 5. This means that for the `virtual-machines-web` module Terraform will loop each resource 5 times, creating 5 NICs, 5 Route53 records, 5 VMs and so on.

### How to scale out

Easily enough, if you want to add another web node to the fleet all you have to do it to set `count` to `6`, run `terraform plan` and, if the plan is acceptable, `terraform apply`.

### How to scale in

Likewise, if there are too many nodes in the fleet and you want to scale in you can set `count` to `4`, `terraform plan` and `terraform apply`.

### How to recycle a node

Recycling a node with Terraform is easily accomplished by tainting the resource and then applying the changes. This gets a little more complicated when dealing with loops. Let's see how.

At the time of this writing our staging environment doesn't use `count` for the web fleet, so the Terraform resource for the `web01` virtual machine is `module.virtual-machines-web.azurerm_virtual_machine.web01`. To recycle this node you can run `terraform taint -module=virtual-machines-web azurerm_virtual_machine.web01`, then `terraform plan` and `terraform apply`.

When Terraform loops through resources a counter is appended to the resource identifier. In production, where the web fleet is treates as cattle, the resource identifier for `web01` is `module.virtual-machines-web.azurerm_virtual_machine.web[0]`. Note that the resource name is now `web` instead of `web01`.

_Note: the counter id for web01 is 0 because the array starts from 0. So_ `web05` _is_ `web[4]` _. Don't get confused with the_ `count` _parameter: that one is intended for humans and Terraform will create that many nodes._

There is a little catch here. `terraform taint` expects a dot notation instead of the square brackets, so to taint web03 in production you'll have to run `terraform taint -module=virtual-machines-web azurerm_virtual_machine.web.2`. Then `plan` and `apply` as always to recycle it.

## Gotchas

At the time of this writing all the secrets are kept in chef vault. This has the downside of only allowing one operation at a time, meaning that if you create three new nodes at once and all three reach the self-registration step roughly at the same time there is a high chance that one or two will fail the vault registration and `chef-client` will fail due to lack of permissions. Until [this issue](https://gitlab.com/gitlab-com/infrastructure/issues/1212) is closed you should create one node at a time.

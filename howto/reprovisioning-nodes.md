# Reprovisioning nodes

Reprovisioning nodes can become a bit of a headache with Chef (mostly Chef Vault to be exact), as there are some considerations that need to be made in order to be able to reprovision a node without errors.

## Steps to reprovision a node (assuming you are using Terraform)

1. Deprovision the VM.
1. Remove the node from Chef using knife: `knife node delete -y myhost.tier.env.gitlab.com`
1. Remove the client from Chef using knife: `knife client delete -y myhost.tier.env.gitlab.com`
1. Remove all the hostname references from Chef Vault
  1. Check which chef-vaults are assigned to the host in Terraform, normally look for `chef_vaults` under `environments/<env>/main.tf` on the corresponding module definition for the role.
  1. Remove the node from the vault with `knife vault remove <vault_name> <vault_item> -S "name:myhost.tier.env.gitlab.com"`
  1. Example: `knife vault remove syslog-client _default -S "name:node01.sv.prd.gitlab.com"`
  1. Example: `knife vault remove gitlab_consul client -S "name:node01.sv.prd.gitlab.com"`
1. You can spin up the node again using `terraform`.
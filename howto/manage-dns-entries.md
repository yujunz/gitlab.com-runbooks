# Manage DNS entries

We use Route 53 to manage DNS entries in our hosted zones through the terraform
environment `dns` on https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure

## Create, edit or delete DNS entries

- Check if the hosted zone you're targeting is already in
[variables.tf](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/blob/master/environments/dns/variables.tf).
If not, create the variable and get the zone id from AWS (remember that you have
to add that value to the CI/CD variables of the gitlab-com-infrastructure
project, and update the `terraform-private/env_vars/common.env` file locally and
in the Production vault in 1Password)
- Establish the variable in which your entry should go. We're using
`"<zone-name>".auto.tfvars.json` files with variables called
`"<zone-name>_<record_type>"` in them. So for example if you were to add a CNAME
record to gitlab.com you'd edit the `gitlab_com_cname` variable on the
[`gitlab_com.auto.tfvars.json` file](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/blob/master/environments/dns/gitlab_com.auto.tfvars.json)
- Create a Merge Request with your changes and ask the SRE team for approval

# Manage DNS entries

We use Route 53 and/or Cloudflare [depending on zone](https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/dns-record/-/blob/master/zones.json) to manage DNS entries in our hosted zones through the terraform
environment `dns` on https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure and also thoughout other environments for terraform bound DNS entries.

## Create, edit or delete DNS entries

- Check if the hosted zone and record type you're targeting is already in
[variables.tf](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/blob/master/environments/dns/variables.tf).
If not, create the variable ([and add the zone](https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/dns-record#zone-configuration)) and get the zone id from AWS and/or Cloudflare, depending on the zone.
- Establish the variable in which your entry should go. We're using
`"<zone-name>".auto.tfvars.json` files with variables called
`"<zone-name>_<record_type>"` in them. So for example if you were to add a CNAME
record to gitlab.com you'd edit the `gitlab_com_cname` variable on the
[`gitlab_com.auto.tfvars.json` file](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/blob/master/environments/dns/gitlab_com.auto.tfvars.json)
- Create a Merge Request with your changes and ask the SRE team for approval

If your record is dependent on the output from creating another terraform resource (e.g. a load balancer), prefer using the [dns-record module](https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/dns-record) directly alongside that other resource, rather than managing the record in the `dns` environment indepedently

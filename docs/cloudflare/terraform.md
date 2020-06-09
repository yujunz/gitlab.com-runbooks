# Cloudflare: Terraform Configuration

## General

The Cloudflare configurations for terraform are found in each environment:

- `main.tf` - Top level zone configuration
- `cloudflare-waf.tf` - WAF package, group, and rule configuration

## References

- [Cloudflare Terraform Provider](https://www.terraform.io/docs/providers/cloudflare/index.html)
- [Cloudflare API Reference](https://api.cloudflare.com/)

## Security

- Rule group configuration is not sensitive and can be included in the public `gitlab-com-infrastructure`.
- Temporary rules for managing incidents should be kept confidential until the incident is resolved at a minimum.

The criteria for what configuration may have high risk is still being developed,
so
* for any operational or incident related rules, follow the
[manual process](cloudflare-managing-traffic.md#manually) and use confidential issues.
* request review from other team members for any other new additions

## Managing Individual Rules

Invididual rules should only be added to the terraform configuration if they
differ from their default settings.

While terraform can manage individual rules, the number of rules causes an
API call for every rule whenever a refresh is done. This can add ~2800 API
calls and 3-5 minutes of run time to `plan` and `refresh` operations. To avoid
this, the following assumption is being made:

**Any rule not present in the terraform configuration is in its default configuration**

### Resetting All Rules to `default` mode

If individual rule settings get out of sync and need to be reset, they can
be reset in bulk with terraform by

* Apply something like configuration below.
* Remove it from the configuration. It will be deleted from the terraform
  state, but the rules will be left in the configured in Cloudflare.

<p>
<details>
<summary>Bulk Rule Set</summary>

```terraform
data "cloudflare_waf_rules" "cloudflare_package_rules" {
  zone_id    = var.cloudflare_zone_id
  package_id = local.cloudflare_package_id
}

resource "cloudflare_waf_rule" "cloudflare-set_to_default" {
  zone_id = var.cloudflare_zone_id
  mode    = "default"

  for_each = {
    for rule in data.cloudflare_waf_rules.cloudflare_package_rules.rules : rule.id => rule.id
  }

  rule_id = each.key
}

data "cloudflare_waf_rules" "owasp_package_rules" {
  zone_id    = var.cloudflare_zone_id
  package_id = local.owasp_package_id
}

resource "cloudflare_waf_rule" "owasp-set_to_default" {
  zone_id = var.cloudflare_zone_id
  mode    = "default"

  for_each = {
    for rule in data.cloudflare_waf_rules.owasp_package_rules.rules : rule.id => rule.id
  }

  rule_id = each.key
}
```

</details>
</p>
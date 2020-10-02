# [Cloudflare](https://cloudflare.com)

Cloudflare provides a web application firewall (WAF), domain name system
(DNS), and content delivery network (CDN) for the following zones:

- gitlab.com
- staging.gitlab.com
- gitlab.net

## [On-Call Reference](oncall.md)

## [Workflow](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10993)

## When to use a Page Rule vs WAF Rules vs [cf_allowlists]

Whatever it is. Create an issue [**in the Firewall tracker**](https://gitlab.com/gitlab-com/gl-infra/cloudflare-firewall/-/issues) first and link it to the relevant issues. This firewall tracker is used to keep track of existing rules. This applies to all rules, regardless of how they are managed.

Next decide whether:
* Is it a redirect or changing a caching policy? Use page rules. Afterwards add an entry in the [`page_rules.json`](https://ops.gitlab.net/gitlab-com/gl-infra/cloudflare-audit-log/-/blob/cloudflare_import/page_rules.json) in the `cloudflare_import` and MR it as described [here](https://ops.gitlab.net/gitlab-com/gl-infra/cloudflare-audit-log#how-do-i-apply-a-cloudflare-change-then)
* Is it a bulk allow of IP addresses for internal customers? Use [cf_allowlists].
* Is it anything else? Use WAF Rules added via the firwall tracker and web UI.

### Quick reference: WAF Rules:

**Temporary rules are subject to automatic expiration!** See [managing traffic](managing-traffic.md) for details.

To make it easier to know where to put the rule priority-wise, categorize the type of rule and pick the priority range from below

- 00000-14999: vulnerability hot-patch (block for everyone)
- 15000-29999: offender blocks (bots, attackers, etc.)
- 30000-44999: general WAF exceptions (bypass for everyone, except offenders)
- 45000-49999: internal and customer allow lists  (managed via [cf_allowlists]. **Not to be used manually**)
- 50000-64999: WAF exceptions or blocks for non-allowlisted users

Then add the firewall tracker issue ID to the range. For example an attack, that is tracked in issue 1234 would get assigned priority `15000+1234` = `16234`.

[cf_allowlists]: https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/cf_allowlists

## [How we use Page Rules and WAF Rules to Counter Abuse and Attacks](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10277)

## Updating the WAF and Page Rules in Cloudflare

### Adding Page Rules Using Terraform
The page rules are managed via Terraform. While changes can be made via the
Cloudflare Web UI, that is not the preferred method to manage rules.

#### Where to make changes
The three zones that use Cloudflare each have a dedicated
`cloudflare-pagerules.tf` file in its Terraform environment.

* [gitlab.net](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/blob/master/environments/ops/cloudflare-pagerules.tf)
* [gitlab.com](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/blob/master/environments/gprd/cloudflare-pagerules.tf)
* [staging.gitlab.com](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/blob/master/environments/gstg/cloudflare-pagerules.tf)

#### How to make changes
The Cloudflare provider for Terraform will not adhere to the `priority` value
set in a page rule's resource. All but the lowest priority rule will need a
`depends_on` section to point to the rule just below it in priority. And the
rule above it will need to be updated to depend on the new rule.

This forces Terraform to apply the rules in a specific order, preserving their
priority.

### Adding WAF Rules to the [cf_allowlists]

With any modification to the WAF rules in Cloudflare, the first step is
creating an issue in the [Firewall Issue Tracker](https://gitlab.com/gitlab-com/gl-infra/cloudflare-firewall).
Refer to the [managing traffic](managing-traffic.md) document to see how to
create the proper issue type with proper labels and description.

[cf_allowlists]
is a Terraform module that we've written to write WAF rules allowing customers'
or GitLab service IPs to bypass Cloudflare and any block that it may cause. The
allowlist is handled in the `allowlist.json` of the linked module. To add an IP
to it, simply update the file with the required information. A sample entry is
provided in the README of the module. Once the change is merged to master, you
will need to run `terraform` on the `gstg` and `gprd` environments to apply the
rules. If you are running it locally, you may need to run `tf init -upgrade` to
ensure you fetch the latest module with your updates.

### Adding WAF Rules via the Web UI

Any modification to the WAF rules in Cloudflare requires an issue in the
[Firewall Issue Tracker](https://gitlab.com/gitlab-com/gl-infra/cloudflare-firewall).
Refer to the [managing traffic](managing-traffic.md) document to see how to
create the proper issues type with proper labels and description.

Making manual changes via the Cloudflare UI can be read about [here](https://developers.cloudflare.com/firewall/cf-dashboard/create-edit-delete-rules/).
A good practice is to create a new rule, but save it as a draft. This will
allow the rule to be turned on and off as part of a production change process.

## Verifying WAF and Page Rules

### How cf_audit works

The [cf_audit project](https://ops.gitlab.net/gitlab-com/gl-infra/cloudflare-audit-log)
is designed to help us keep a "known good" dump of our Cloudflare configuration.
This is only an audit tool and not used to update any configuration on its own.
The script itself gets all of the configuration data for our Cloudflare zones
and account from the API and outputs the data into the `reports/` directory of
the project.

There is a CI job that runs periodically to gather said data and commit it to
the `cloudflare_import` branch. The `cloudflare_import` branch is considered
the source of truth for the configuration. It then compares this information to
the `known_good` branch to determine what (if anything) has changed. The
`known_good` branch is considered to be the expected configuration. If a
configuration has changed, the job will be marked as failed, prompting manual
review of the changes.

If you'd like to watch a more detailed video about its inner workings, you can
view [this demonstration video](https://youtu.be/vTKyf-PS7Lo) which goes into
much more detail.

### [How Page Rules work](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10989)

## General Information
* [Vendor Info](./vendor.md)
* [Services Locations](./services-locations.md)
* [WAF Service Information](../waf/README.md)

## Domain Name System (DNS)
* For the zones listed above, Cloudflare is the DNS resolver.
* [DNS in Terraform](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/tree/master/environments/dns) is used to manage Cloudflare DNS entries.


<!-- ## Summary -->

<!-- ## Architecture -->

<!-- ## Performance -->

<!-- ## Scalability -->

<!-- ## Availability -->

<!-- ## Durability -->

<!-- ## Security/Compliance -->

<!-- ## Monitoring/Alerting -->

<!-- ## Links to further Documentation -->

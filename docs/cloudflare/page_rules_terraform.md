# Page Rules via Terraform
The page rules are managed via Terraform. While changes can be made via the
Cloudflare Web UI, that is not the preferred method to manage rules.

## Where to make changes
The three zones that use Cloudflare each have a dedicated
`cloudflare-pagerules.tf` file in its Terraform environment.

* [gitlab.net](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/blob/master/environments/ops/cloudflare-pagerules.tf)
* [gitlab.com](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/blob/master/environments/gprd/cloudflare-pagerules.tf)
* [staging.gitlab.com](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/blob/master/environments/gstg/cloudflare-pagerules.tf)

## How to make changes
The Cloudflare provider for Terraform will not adhere to the `priority` value
set in a page rule's resource. All but the lowest priority rule will need a
`depends_on` section to point to the rule just below it in priority. And the
rule above it will need to be updated to depend on the new rule.

This forces Terraform to apply the rules in a specific order, preserving their
priority.

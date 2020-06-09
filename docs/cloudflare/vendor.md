# Accessing and Using CloudFlare

Users that have been provisioned can access Cloudflare directly at
`https://dash.cloudflare.com`.

## Baseline Entitlements and Provisioning

CloudFlare Administrator Access is a baseline entitlement for SRE. Authentication
is done via Okta, but SCIM is not supported so team members must be invited
using the CloudFlare dashboard.

Instructions for Access Provisioners (requires Super Administrator privileges):

1. Log in to the dashboard at https://dash.cloudflare.com.
2. Navigate to the "GitLab" account.
3. Select the "Members" tab.
4. Select the permission level. Be user to unselect "Administrator" when selecting "Administrator Read Only", it is not automatically unselected.
5. Enter the team members emails and click "Invite".

# Configuraion

## Creating or Editing Custom Rules

TODO: link to terraform module

### Managing Traffic (blocks and allowlists)

[Cloudflare: Managing Traffic](./cloudflare-managing-traffic.md)

## Anti-Abuse Investigations

TODO: List some common things to filter on in the Firewall tab.

## Managing Workers

Interim documentation: https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/cloudflare_workers#configuration

# Getting support from Cloudflare

## Contacting support


## Contact Numbers

Should we need to call Cloudflare, we were given these numbers to reach out to for help.

There are a few noted with a # that can only be called from the country specified.

Local Enterprise phone numbers for each country:

- United States: +1 650-353-5922
- United Kingdom: +44 808-169-9540
- India Toll-Free Number: 0008000501934 #
- South Korea Toll-Free Number:  00798 142030193 #
- Taiwan Toll-Free Number: +886 (80) 1491362  (To dial from within Taiwan: 00801-491-362)
- Australia Toll-Free Number: +61 (1800) 491698
- New Zealand Toll-Free Number: +64 (80) 0758909
- Japan: +81 503-196-5771
- Brazil: +55 114-950-8998, +55-11-4949-5922
- Canada: +1 647-360-8385
- Mexico +52-155-4169-5968
- Chile +56-2-2666-5928
- Singapore +65 800-321-1182 #
- China +86 (10) 85241784
- Portugal +351 (21) 1230925
- Germany +49 89 2555 2787

# Other References

## Implementation Epic

https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/94

## Readiness review

https://gitlab.com/gitlab-com/gl-infra/readiness/blob/master/cloudflare/README.md

## Issue Tracker for Evaluation

**Cloudflare Vendor Tracker**: https://gitlab.com/gitlab-com/gl-infra/cloudflare/issues

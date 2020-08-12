# [Cloudflare](https://cloudflare.com)

Cloudflare provides a web application firewall (WAF), domain name system
(DNS), and content delivery network (CDN) for the following zones:

- gitlab.com
- staging.gitlab.com
- gitlab.net

## [On-Call Reference](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10986)

## [Workflow](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10993)

## When to use a Page Rule vs WAF Rules vs cf_allowlists - ???

* Is it a redirect or changing a caching policy? Use page rules.
* Is it a bulk allow of IP addresses for internal customers? Use cf_allowlists.
* Is it anything else? Use WAF Rules added via the firwall tracker and web UI.

## [How we use Page Rules and WAF Rules to Counter Abuse and Attacks](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10277)

## Updating the WAF and Page Rules in Cloudflare

### [Adding Page Rules Using Terraform](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10989)

### [Adding WAF Rules to the cf_allowlists](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10987)

### [Adding WAF Rules via the Web UI](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10988)

## Verifying WAF and Page Rules

### [How cf_audit works](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10993)

### [How Page Rules work](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10989)

## General Information
* [Vendor Info](./vendor.md)
* [Services Locations](./services-locations.md)
* [WAF Service Information](../waf/service-waf.md)

## Domain Name System (DNS)
* For the zones listed above, Cloudflare is the DNS resolver.
* [DNS in Terraform](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/tree/master/environments/dns) is used to manage Cloudflare DNS entries.

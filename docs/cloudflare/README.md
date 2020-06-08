# Cloudflare

Cloudflare provides a web application firewall (WAF), domain name system
(DNS), and content delivery network (CDN) for the following zones:

- gitlab.com
- staging.gitlab.com
- gitlab.net

## On-Call
* [Logging](logging.md)
* [Managing Taffic](../waf/cloudflare-managing-traffic.md)

## General Information
* [Vendor Info](../waf/clouflare-vendor.md)
* [Terraform Management](../wf/cloudflare-terraform.md)

## Web Application Firewall (WAF)
* [Service Information](../waf/service-waf.md)

## Domain Name System (DNS)
* For the zones listed above, Cloudflare is the primary DNS resolver.
* Route53 in AWS is a secondary resolver.
* Terraform is used to manage Cloudflare DNS entries.

## Content Deliver Network (CDN)
* As of the writing of this page, we are caching nothing in Cloudflare.

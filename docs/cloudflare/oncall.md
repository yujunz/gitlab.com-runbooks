# Cloudflare for the on-call

## Using Cloudflare to look for problems

The firewall section of the Cloudflare web UI is a convenient way to filter
on specific meta-data to find problematic traffic. This interface is also
very useful to see what firewall rules are being applied to traffic.

- [Understanding Cloudflare Firewall Analytics](https://support.cloudflare.com/hc/en-us/articles/360024520152-Understanding-Cloudflare-Firewall-Analytics)

## Using Cloudflare to stop problems

** During an incident, making changes to the firewall rules and page rules
is expected. But be certain you follow proper process afterwards to make
certain that the changes are reflected in the right locations and follow the
Cloudflare rules management processes. **

### Adding firewall rules
A firewall rule should be used for the following types of actions:

* Blocking an IP address
* Adding captcha challenges to a path
* Prevent WAF rules from blocking legitimate traffic

Firewall rules can match against many types of request attributes.

- [Manage firewall rules in the Cloudflare UI](https://developers.cloudflare.com/firewall/cf-dashboard)

### Adding page rules
A page rule should be used for the following types of actions:

* Redirecting requests of a certain URL to another location
* Modifying cache policy for certain URL

Keep in mind that page rules can only match on request paths.

- [Understanding and Configuring Cloudflare Page Rules](https://support.cloudflare.com/hc/en-us/articles/218411427-Understanding-and-Configuring-Cloudflare-Page-Rules-Page-Rules-Tutorial-)

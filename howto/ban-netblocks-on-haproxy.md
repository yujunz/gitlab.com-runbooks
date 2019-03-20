# Blocking individual IPs and Net Blocks on HA Proxy

## First and foremost

* *Don't Panic*
* Be careful when manipulating the ip blacklist.

## Background

From time to time it may become necessary to block IP addresses or networks of IP addresses from accessing GitLab.
We do this by managing those IP adresses in the file 
[deny-403-ips.lst](https://gitlab.com/gitlab-com/security-tools/front-end-security/blob/master/deny-403-ips.lst) in the
[security-tools/front-end](https://gitlab.com/gitlab-com/security-tools/front-end-security) repository. Updates to this file
are distributed to the HA Proxy nodes on each chef run by the [gitlab-haproxy](https://gitlab.com/gitlab-cookbooks/gitlab-haproxy) cookbook.

The gitlab.com repo is mirrored by the ops.gitlab.net instance and the `gitlab-haproxy` role is picking up changes from there!



## How do I

### See what IP addresses are currently blocked

Open [deny-403-ips.lst](https://gitlab.com/gitlab-com/security-tools/front-end-security/blob/master/deny-403-ips.lst).

Or, on a haproxy node, look into `/etc/haproxy/front-end-security/deny-403-ips.lst`.

### Add a netblock to the blackhole

Just like Santa Clause, you want to check your list twice before you sort the naughties into the blackhole.

* Edit and commit [deny-403-ips.lst](https://gitlab.com/gitlab-com/security-tools/front-end-security/blob/master/deny-403-ips.lst).
  * All IP addresses must have a subnet mask, even if it's a single address (/32).
* Wait for changes to be mirrored to the ops.gitlab.net instance and for the next chef run to pick them up and reload haproxy on the LBs.

How can we make this go faster?

* Manually force the mirror sync in the [repo settings](https://ops.gitlab.net/gitlab-com/security-tools/front-end-security/settings/repository)
* run chef client on the haproxy nodes:

```
knife ssh 'roles:gprd-base-lb' sudo chef-client
```

### Remove a netblock from the blackhole

Same as above.

## CLEAN UP

It is important to note that blackhole entires ***DO NOT*** clean up after themselves, you must remove the entries
after the threat or issue has been mitigated / resolved.  When a network is blackholed the users are not able to reach
ANY of the GitLab infrastructure that depends upon the HA Proxies (almost all of it!). This makes it even more important
that you clean up after yourself. You will probably want to work together with the abuse team and support.

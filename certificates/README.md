# Gitlab Certificate Run Books

This is an overview of certificates, where they are used and how they can be replaced in their service.

## Deployment and replacement strategies

Currently we have multiple ways of deploying certificates. Please see the `Management` and `Details` columns to find the management process and other details to edit according to that documentation.

- [Chef Vault][cv]
- [Chef Server][cs]
- [Chef Hybrid][chef_hybrid]
- [Fastly][f]
- [Forum][fo]
- [Gitter.im][gitter]
- [GCP Load Balancer][gcp]
- [GKMS][gkms] (mostly automated using [Certificates Updater](https://gitlab.com/gitlab-com/gl-infra/certificates-updater))
- [Status.io][statusio]
- [ZenDesk][zd]

## General info

- COMODO has renamed to Sectigo, those names might get used interchangeably in this document. Any Certificate that is listed as issued by COMODO will in the future be issued by Sectigo.
- Our primary certificate source is [SSMLate](https://sslmate.com/console/orders/).
  - Using the above link it is possible to retrieve the current certificate file for each CN listed there.
  - Those files are permanent links to the public chain of the certificate. The key is *not* part of that chain.
  - Some tasks require the commandline tool (available via https://sslmate.com/help/install and `brew install sslmate`).

### Buy a new certificate

###### Before buying a new certificate, please check if it is possible to use an automated Let's Encrypt certificate for your purpose!

```
sslmate buy '<domain>' --auto-renew --approval=dns --key-type=ecdsa
```

Use `sslmate help buy` for additional options if needed.

But with the above example, this will purchase a certificate that expires after
1 year, will auto renew itself using DNS, and is of key type `ecdsa`.

We've chosen to go with `ecdsa` for it's improvements:
* Smaller size
* Improved TLS handshake speed
* Stronger algorithm

We have [Route53 integration with SSLMate](https://sslmate.com/account/integrations/add/aws)
so the DNS authorization will be done automatically.

The `sslmate` client will download the key and certificate to the directory in
which the command was executed.

*Make sure to add the new certificate to the list below!*

Also create a 1Password entry for the key (and the new cert) in the "SSLCerts Lockbox" vault.

### Renew a certificate

For older certificates we may not have renewal properly configured.  Let's
change that:
```
sslmate edit '<domain>' --approval=dns
sslmate renew '<domain>'
```

This will change the existing approval method to our fancy DNS integration, and
then force a renew.  You can then download the certificate:
```
sslmate download '<domain>'
```

Note that sslmate may complain that you won't have the key in your `${CWD}`.
This is fine as we should have the key on minimally on a server, but may also
exist inside of 1Password, and even better, inside a chef vault.

### Re-keying a certificate

If a certificate auto-renews but we have lost the private key, generate a new
one (and CSR) using SSLMate's web UI. Download the private key and create a
1password entry for it (and the new cert) in the "SSLCerts Lockbox" vault.

### Verify the certificate

Wait for chef to converge, or force a convergence.

Use a tool such as https://www.sslshopper.com/ssl-checker.html or https://www.ssllabs.com/ssltest/index.html to verify that the certificate is live, working, and fully valid.

### Monitoring

We utilize prometheus blackbox to regularly check endpoints and send us alerts
when those endpoints go down as well as validate and alert us at a threshold
when those certificates are going to expire.

* https://gitlab.com/gitlab-com/runbooks/blob/master/rules/ssl-certificate-expirations.yml

#### Modify list of hosts with SSL certificate

By editing list inside `prometheus.jobs.blackbox-ssl.target` attribute in the role `prometheus-server` on chef, you can add or remove server from monitoring for SSL certificate expiration. By adding server there you will be receiving alerts when there is less than 30 days remain for certificate expiration. Do not forget to save your changes to chef-repo and run chef-client on prometheus host to see changes.


### Safe execution of a update involving chef nodes

- Preparation:
  1. Check the state of chef-client: `knife ssh "roles:${chef_role} AND chef_environment:${chef_env}" "ps -aux | grep chef-client | grep -v grep"`
  1. Stop chef on the haproxy fleet that serves the cert in question.
    * ```knife ssh "role:<role name>" "sudo service chef-client stop"```
- Do the change according to the table below
- Slowly roll out chef
  1. Inspect changes that would be applied on one of the nodes: `sudo chef-client --why-run`
  1. Force a chef-run on one of the nodes for verification. You should be able to simply run ```sudo chef-client``` and see the updated certificate in the output.
  1. Use openssl to verify the correct certificate is in place:
    * `openssl s_client -connect ${NODE IP ADDRESS}:443 -servername ${HOSTNAME} </dev/null 2>/dev/null | openssl x509 -noout -text`
    * check for dates and general information to match, such as the CN and SANs.
  1. Restart chef on the nodes from the first step.
    * ```knife ssh "role:${chef_role} AND chef_environment:${chef_env}" "sudo service chef-client start"```


## Certificates and their use

### Certificates currently managed by the GitLab Infrastructure team:

| domain | issuer |  Comments | Management | Details |
| ------ | ------ | --------- | ---------- | ----- |
| about-src.gitlab.com, *.about-src.gitlab.com, about.gitlab-review.app, *.about.gitlab-review.app | COMODO RSA Domain Validation Secure Server CA | about-src.gitlab.com is no longer used, but the CN of the cert / The other SANs are used for GitLab review apps for `www-gitlab-com` | [Chef Vault][cv] | data bag: `about-gitlab-com`, item: `_default`, fields: `ssl_certificate`, `ssl_key` |
| about.gitlab.com | GlobalSign CloudSSL CA - SHA256 - G3 | CDN Certificate for about.gitlab.com | [Fastly][f] | Auto-renewed shared certificate |
| canary.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | Canary direct access | [GKMS][gkms] | item: `frontend-loadbalancer gprd`, fields: `gitlab-haproxy.ssl.canary_crt`,  `gitlab-haproxy.ssl.canary_key` |
| ce.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | Redirect to CE repo, hosted on about-src., no CDN | [Chef Vault][cv] | data bag: `about-gitlab-com`, item: `_default`, fields: `[ce.gitlab.com][ssl_certificate]`, `[ce.gitlab.com][ssl_key]` |
| chef.gitlab.com | COMODO RSA Domain Validation Secure Server CA | Chef server | [Chef Server][cs] | - |
| contributors.gitlab.com | GlobalSign CloudSSL CA - SHA256 - G3 | Redirect to gitlab.biterg.io, hosted on fastly | [Fastly][f] | Auto-renewed shared certificate |
| customers.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | Customer management | [Chef Vault][cv] | data bag: `customers-gitlab-com`, item: `_default`, fields: `ssl_certificate`, `ssl_key` |
| dashboards.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | Public grafana | [GCP Load Balancer][gcp] | project: `gitlab-ops` |
| dashboards.gitlab.net | Sectigo RSA Domain Validation Secure Server CA | Internal grafana | [GCP Load Balancer][gcp] | project: `gitlab-ops`|
| dev.gitlab.org | COMODO RSA Domain Validation Secure Server CA | dev instance | [Chef Vault][cv] | data bag: `dev-gitlab-org`, item: `_default`, fields: `ssl.certificate`, `ssl.private_key` |
| docs.gitlab.com | Let's Encrypt Authority X3 | - | automatic (GitLab Pages managed) | |
| dr.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | Disaster recovery instance | [GKMS][gkms] | item: `frontend-loadbalancer dr`, fields: `gitlab-haproxy.ssl.gitlab_crt`,  `gitlab-haproxy.ssl.gitlab_key`|
| ee.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | Redirect to EE repo, hosted on about-src., no CDN | [Chef Vault][cv] | data bag: `about-gitlab-com`, item: `_default`, fields: `[ee.gitlab.com][ssl_certificate]`, `[ee.gitlab.com][ssl_key]` |
| forum.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | GitLab forum | [Forum][fo] | |
| gitlab.com | Sectigo RSA Domain Validation Secure Server CA | Duh | [GKMS][gkms] | item: `frontend-loadbalancer gprd`, fields: `gitlab-haproxy.ssl.gitlab_crt`,  `gitlab-haproxy.ssl.gitlab_key` |
| gitlab.org | GlobalSign CloudSSL CA - SHA256 - G3 | Redirect to about.gitlab.com, hosted on fastly | [Fastly][f] | Auto-renewed shared certificate |
| hub.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | redirects to https://lab.github.com/ (https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/6667), hosted on about-src, no CDN | [Chef Vault][cv] | data bag: `about-gitlab-com`, item: `_default`, fields: `[hub.gitlab.com][ssl_certificate]`, `[hub.gitlab.com][ssl_key]` |
| jobs.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | redirects to https://about.gitlab.com/jobs/, Hosted on about-src | [Fastly][f] & [Chef Vault][cv] | data bag: `about-gitlab-com`, item: `_default`, fields: `[jobs.gitlab.com][ssl_certificate]`, `[jobs.gitlab.com][ssl_key]` |
| license.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | | [Chef Vault][cv] | data bag: `license-gitlab-com`, item: `_default`, fields: `[gitlab-packagecloud][ssl_certificate]`, `[gitlab-packagecloud][ssl_key]` |
| log.gitlab.net | Sectigo RSA Domain Validation Secure Server CA | | [GCP Load Balancer][gcp] | project: `gitlab-ops` ops-proxy |
| monitor.gitlab.net | Amazon Server CA 1B | AWS CloudFront redirect to dashboards.gitlab.net. | - | Auto-renewed by Amazon |
| next.gitlab.com | Let's Encrypt Authority X3 | - | automatic (GitLab Pages managed) | |
| nonprod-log.gitlab.net | Sectigo ECC Domain Validation Secure Server CA | non prod logs | [GCP Load Balancer][gcp]  | project: `gitlab-ops` ops-nonprod-proxy |
| ops.gitlab.net | COMODO RSA Domain Validation Secure Server CA | ops instance  | [GKMS][gkms] | item: `gitlab-omnibus-secrets ops`, fields: `omnibus-gitlab.ssl.certificate`,  `omnibus-gitlab.ssl.private_key` |
| packages.gitlab.com | COMODO RSA Domain Validation Secure Server CA | packagecoud instance | [Chef Vault][cv] | data bag: `packages-gitlab.com`, item: `_default`, fields: `ssl.certificate`, `ssl.private_key` |
| pre.gitlab.com | COMODO RSA Domain Validation Secure Server CA | prerelease instance | [GKMS][gkms] | item: `frontend-loadbalancer pre`, fields: `gitlab-haproxy.ssl.gitlab_crt`,  `gitlab-haproxy.ssl.gitlab_key` |
| prod.pages-check.gitlab.net | COMODO RSA Domain Validation Secure Server CA | [GitLab pages check](https://gitlab.com/gitlab-com/pages-ip-check) | automatic (GitLab Pages managed) | |
| prometheus-01.us-east1-c.gce.gitlab-runners.gitlab.net | COMODO RSA Domain Validation Secure Server CA | | [Chef Vault][cv] | data bag: `gitlab-runners-prometheus-gce-us-east1-c`, item: `ci-prd`, fields: `gitlab-oauth2-proxy.nginx.ssl_certificate`, `gitlab-oauth2-proxy.nginx.ssl_key` |
| prometheus-01.us-east1-d.gce.gitlab-runners.gitlab.net | COMODO RSA Domain Validation Secure Server CA | | [Chef Vault][cv] | data bag: `gitlab-runners-prometheus-gce-us-east1-d`, item: `ci-prd`, fields: `gitlab-oauth2-proxy.nginx.ssl_certificate`, `gitlab-oauth2-proxy.nginx.ssl_key` |
| prometheus.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | | [Chef Vault][cv] | data bag: `gitlab-oauth2-proxy-prometheus`, item: `prd`, fields: `ssl_certificate`, `ssl_key` |
| registry.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | | [GKMS][gkms] | item: `frontend-loadbalancer gprd`, fields: `gitlab-haproxy.ssl.registry_crt`,  `gitlab-haproxy.ssl.registry_key` |
| registry.ops.gitlab.net | Sectigo RSA Domain Validation Secure Server CA | | [GKMS][gkms] | item: `gitlab-omnibus-secrets ops`, fields: `omnibus-gitlab.ssl.registry_certificate`,  `omnibus-gitlab.ssl.registry_private_key`|
| registry.pre.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | | [GKMS][gkms] | item: `frontend-loadbalancer pre`, fields: `gitlab-haproxy.ssl.registry_crt`,  `gitlab-haproxy.ssl.registry_key` |
| registry.staging.gitlab.com | COMODO RSA Domain Validation Secure Server CA | | [GKMS][gkms] | item: `frontend-loadbalancer gstg`, fields: `gitlab-haproxy.ssl.registry_crt`,  `gitlab-haproxy.ssl.registry_key` |
| sentry.gitlab.net | COMODO RSA Domain Validation Secure Server CA | | [Chef hybrid][chef_hybrid] | cert role: `ops-infra-sentry` cert field: `default_attributes.gitlab-sentry.ssl_certificate`, key data bag: `gitlab-sentry`, key items: `_default` *and* `prd`, key fields: `gitlab-sentry.ssl_key` |
| staging.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | staging instance | [GKMS][gkms] | item: `frontend-loadbalancer gstg`, fields: `gitlab-haproxy.ssl.gitlab_crt`,  `gitlab-haproxy.ssl.gitlab_key` |
| staging.pages-check.gitlab.net | COMODO RSA Domain Validation Secure Server CA | [GitLab pages check](https://staging.gitlab.com/gitlab-com/pages-ip-check) | automatic (GitLab Pages managed) | |
| status.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | status.io | | [Status.io][statusio] |
| support.gitlab.com | Let's Encrypt Authority X3 | General zendesk | [ZenDesk][zd] | |
| swedish.chef.gitlab.com | COMODO RSA Domain Validation Secure Server CA | Chef server, that hosts some remains of GitHost.io | [Chef Server][cs] | Could not be validated, due to lack of access. |
| user-content.staging.gitlab-static.net | Sectigo ECC Domain Validation Secure Server CA | | [GCP Load Balancer][gcp] | project: `gitlab-production` |
| version.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | | [Chef Vault][cv] | data bag: `version-gitlab-com`, item: `_default`, fields: `ssl_certificate`, `ssl_key` |
| *.gitlab.io | C=BE, O=GlobalSign nv-sa, CN=AlphaSSL CA - SHA256 - G2 | GitLab pages | [GKMS][gkms] | item: `gitlab-omnibus-secrets gprd`, fields: `omnibus-gitlab.ssl.pages_certificate`,  `omnibus-gitlab.ssl.pages_private_key` |
| *.gitter.im | COMODO RSA Domain Validation Secure Server CA | gitter.im | [Gitter.im][gitter] ||
| *.gprd.gitlab.net | Sectigo RSA Domain Validation Secure Server CA | | [GCP Load Balancer][gcp] | project: `gitlab-production` |
| *.gstg.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | | [GCP Load Balancer][gcp] | project: `gitlab-staging` |
| *.gstg.gitlab.io | Sectigo RSA Domain Validation Secure Server CA | GitLab pages on gstg | [GKMS][gkms] | item: `gitlab-omnibus-secrets gstg`, fields: `omnibus-gitlab.ssl.pages_certificate`,  `omnibus-gitlab.ssl.pages_private_key` |
| *.gstg.gitlab.net | Sectigo RSA Domain Validation Secure Server CA | | [GCP Load Balancer][gcp]  | project: `gitlab-staging` |
| *.ops.gitlab.net | Sectigo RSA Domain Validation Secure Server CA | | [GCP Load Balancer][gcp] | project: `gitlab-ops` |
| *.pre.gitlab.net | Sectigo RSA Domain Validation Secure Server CA | | [GCP Load Balancer][gcp] | project: `gitlab-pre` |
| *.pre.gitlab.io | Sectigo RSA Domain Validation Secure Server CA | GitLab pages for pre | [GKMS][gkms] | item: `gitlab-omnibus-secrets pre`, fields: `omnibus-gitlab.ssl.pages_certificate`,  `omnibus-gitlab.ssl.pages_private_key` |
| *.qa-tunnel.gitlab.info | Sectigo RSA Domain Validation Secure Server CA | QA Tunnel | [Chef Vault][cv] | data bag: `gitlab-qa-tunnel`, item: `ci-prd`, fields: `"gitlab-qa-tunnel".ssl_certificate`, `"gitlab-qa-tunnel".ssl_key`|

Defunct certs (dead hosts, no longer used, etc)

| domain | issuer | valid until | Comments |
| ------ | ------ | ----------- | -------- |
| alerts.gitlabhosted.com | COMODO RSA Domain Validation Secure Server CA | 2020-01-03T23:59:59 | GitHost related |
| alerts.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-06-24T23:59:59 | Active certificate, but not rolled out to the CN host. |
| allremote.org | Sectigo RSA Domain Validation Secure Server CA | 2020-06-08T23:59:59 | Page 404s with HTTP, and `NET::ERR_CERT_COMMON_NAME_INVALID` on HTTPS. Is a gitlab.io page. |
| canary.staging.gitlab.com | COMODO RSA Domain Validation Secure Server CA | 2019-09-06T23:59:59 | Connection to host times out |
| canary.staging.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-09-06T23:59:59 |
| convdev.io | Sectigo RSA Domain Validation Secure Server CA | 2020-05-30T23:59:59 | Current certificate, but not rolled out |
| redash.gitlab.com | COMODO RSA Domain Validation Secure Server CA | | Hosted on version.gitlab.com. Redash is no longer chef managed. |
| registry.gke.gstg.gitlab.com | Let's Encrypt Authority X3 | 2019-09-24T17:49:51 | Was retrieved, but is not used. Verified by jarv |
| registry.gke.pre.gitlab.com | Let's Encrypt Authority X3 | 2019-08-26T16:53:33 | Same as `registry.gke.gstg.gitlab.com` |
| registry.gke.staging.gitlab.com | Let's Encrypt Authority X3 | 2019-09-24T18:07:16 | Same as `registry.gke.gstg.gitlab.com` |
| enable.gitlab.com | Let's Encrypt Authority X3 | 2019-10-14T21:09:02 | Site is a 404 |
| geo1.gitlab.com | COMODO RSA Domain Validation Secure Server CA | 2019-11-02T23:59:59 | Does not resolve |
| geo2.gitlab.com | COMODO RSA Domain Validation Secure Server CA | 2019-11-15T23:59:59 | Does not resolve |
| gprd.gitlab.com | COMODO RSA Domain Validation Secure Server CA | 2020-02-06T23:59:59 | does not resolve |
| gstg.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-04-11T23:59:59 | does not resolve |
| log.gitlap.com | Sectigo RSA Domain Validation Secure Server CA | 2020-06-02T23:59:59 | Replaced by log.gitlab.net |
| monkey.gitlab.net | COMODO RSA Domain Validation Secure Server CA | 2020-02-27T23:59:59 | does not resolve |
| next.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | - | Replaced with auto-renewed Let's Encrypt certificate (GitLab pages) |
| next.staging.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-02-22T23:59:59| Does not work as of now, but should be fixed to work in the future (via LE certificate) |
| performance-lb.gitlab.net | Sectigo RSA Domain Validation Secure Server CA | 2020-05-17T23:59:59 | does not resolve |
| plantuml.pre.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | | No longer in use |
| prod.geo.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-08-14T23:59:59 | does not resolve |
| prod-log.gitlab.net | Sectigo RSA Domain Validation Secure Server CA | 2020-08-30T23:59:59 | initially used for the production logs cluster, we later decided to use log.gprd.gitlab.net instead |
| prometheus-01.nyc1.do.gitlab-runners.gitlab.net | COMODO RSA Domain Validation Secure Server CA | 2019-11-06T23:59:59 | times out |
| prometheus-2.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-06-25T23:59:59 | times out |
| prometheus-3.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-06-25T23:59:59 | times out |
| prometheus-app-01.gitlab.net | COMODO RSA Domain Validation Secure Server CA | 2020-02-16T23:59:59 | times out |
| prometheus-app-02.gitlab.net | COMODO RSA Domain Validation Secure Server CA | 2020-02-16T23:59:59 | times out |
| prometheus.gitlabhosted.com | COMODO RSA Domain Validation Secure Server CA | 2019-11-28T23:59:59 | cert not rolled out to host |
| runners-cache-5.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-06-07T23:59:59 | does not resolve |
| sentry-infra.gitlap.com | Sectigo RSA Domain Validation Secure Server CA | 2020-05-26T23:59:59 | connection refused |
| snowplow.trx.gitlab.net | Sectigo RSA Domain Validation Secure Server CA | 2020-07-03T23:59:59 | time out |
| sync.geo.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-08-17T23:59:59 | does not resolve |
| *.ce.gitlab-review.app | COMODO ECC Domain Validation Secure Server CA | 2019-10-03T23:59:59 | time out |
| *.ce.gitlab-review.app | Sectigo ECC Domain Validation Secure Server CA | 2020-10-03T23:59:59 | time out |
| *.design.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-04-27T23:59:59 | site uses a LE cert generated by gl pages. Wildcard is not installed. This cert is dead |
| *.dr.gitlab.net | Sectigo ECC Domain Validation Secure Server CA | 2020-01-23T23:59:59 | does not resolve |
| *.ee.gitlab-review.app | COMODO ECC Domain Validation Secure Server CA | 2019-10-03T23:59:59 | times out |
| *.eks.helm-charts.win | Sectigo RSA Domain Validation Secure Server CA | 2020-04-01T23:59:59 | does not resolve |
| *.githost.io | Sectigo RSA Domain Validation Secure Server CA | 2020-05-03T23:59:59 | wildcard is dead (does not resolve) and githost is shut down (but githost.io still reachable) |
| *.gitlab-review.app | COMODO RSA Domain Validation Secure Server CA | 2019-09-10T23:59:59 | does not resolve |
| *.gprd.gitlab.com | COMODO RSA Domain Validation Secure Server CA | - | No longer in used (was used before `gitlab.net`) |
| *.helm-charts.win | COMODO RSA Domain Validation Secure Server CA | 2019-11-08T23:59:59 | times out |
| *.k8s-ft.win | COMODO RSA Domain Validation Secure Server CA | 2019-11-08T23:59:59 | times out |
| *.pre.gitlab.com | COMODO RSA Domain Validation Secure Server CA | - | Not required |
| *.separate-containers.party | COMODO RSA Domain Validation Secure Server CA | 2019-11-08T23:59:59 | does not resolve |
| *.single.gitlab.com | COMODO RSA Domain Validation Secure Server CA | 2019-09-12T23:59:59 | does not resolve |
| *.single.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-09-12T23:59:59 | |
| *.staging.gitlab.io | Sectigo RSA Domain Validation Secure Server CA | 2020-06-25T23:59:59 | Gitlab pages on staging, was not updated on hosts, is it still used? There IS *.gstg.gitlab.io which is working |
| *.testbed.gitlab.net | Sectigo RSA Domain Validation Secure Server CA | 2020-05-03T23:59:59 | does not resolve |

Other Certs (Unknown maintainer)

| domain | issuer | valid until | Comments |
| ------ | ------ | ----------- | -------- |
| federal-support.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-05-22T23:59:59 | US Federal Zendesk instance |
| federal-support.gitlab.com | Let's Encrypt Authority X3 | 2019-09-29T18:11:39 | |
| learn.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-05-30T23:59:59 | redirects to https://gitlab.lookbookhq.com/users/sign_in |
| page.gitlab.com | CloudFlare, Inc. | | redirect to about. (Non infra managed as CF renews automagically) |
| page.gitlab.com | CloudFlare, Inc. | | |
| saml-demo.gitlab.info | Sectigo RSA Domain Validation Securchef_hybride Server CA | 2020-05-18T23:59:59 | |
| saml-demo.gitlab.info | Let's Encrypt Authority X3 | 2019-10-23T19:46:50 | |
| shop.gitlab.com | Let's Encrypt Authority X3 | 2019-10-09T19:47:35 | Swag shop |
| shop.gitlab.com | CloudFlare, Inc. | | |
| shop.gitlab.com | CloudFlare, Inc. | | |
| translate.gitlab.com | Let's Encrypt Authority X3 | 2019-10-04T02:12:34 | GitLab translation site |
| www.meltano.com | COMODO RSA Domain Validation Secure Server CA | 2019-09-07T23:59:59 | Maybe mananaged by infra? |
| *.cloud-native.win | COMODO RSA Domain Validation Secure Server CA | 2019-11-08T23:59:59 | looks like a k8s cluster |

[cv]: chef_vault.md
[cs]: chef_server.md
[chef_hybrid]: chef_hybrid.md
[f]: fastly.md
[fo]: forum.md
[gitter]: https://gitlab.com/gitlab-com/gl-infra/gitter-infrastructure/tree/master#update-sslhttps-certs
[gkms]: gkms.md
[gcp]: gcp.md
[statusio]: https://app.status.io/dashboard/5b36dc6502d06804c08349f7/settings/ssl
[zd]: zendesk.md

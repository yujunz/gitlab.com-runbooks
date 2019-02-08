# SSL Certificates

We use [SSLMate] for ordering SSL certificates. Get the commandline tool via
https://sslmate.com/help/install. If you're using Homebrew you can install it with `brew install sslmate`.

Credentials are in 1Password.

### Buy a new certificate

```
sslmate buy '<domain>' --auto-renew --approval=dns --key-type=ecdsa
```

Use `sslmate help buy` for additional options if needed.

But with the above example, this will purchase a certificate that expires after
1 year, will auto renew itself using DNS, and is of key type `ecdsa`.

We've chosen to go with `ecdsa` for it's improvements:
* Smaller size
* Improved speed for TLS handshaking
* Stronger algorithm

We have [Route53 integration with SSLMate](https://sslmate.com/account/integrations/add/aws)
so the DNS authorization will be done automatically.

The `sslmate` client will download the key and certificate to the directory in
which the command was executed.

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

### Use Rake to update vault

Since we store the certificate or at least the key always in a vault, update it with the new certificate and key.

```
cd chef-repo/
rake 'edit_role_secrets[the_role_with_vault]'
```

To convert the multi-line key and certificate files to a single-line string
suitable for the vault, use this command:

```
awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' [domain].key

awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' [domain].chained.crt

**Note:** You _must_ use the `[domain].chained.crt` certificate file, _not_ the
`[domain].crt` file!

```

### Upload certificate to GCP

If your certificate is to be used by a GCP resource (for example, a load
balancer) you can upload it using this command:

```
gcloud compute ssl-certificates create [CERTIFICATE_NAME] --certificate [PATH_TO_CRT] --private-key [PATH_TO_KEY] --project [PROJECT_NAME]
```

The certificate will then be available at the following resource route:
`projects/[PROJECT_NAME]/global/sslCertificates/[CERTIFICATE_NAME]` (you may
have to specify that resource path to the relevant terraform module).

**Note:** You _must_ use the `[domain].chained.crt` certificate file, _not_ the
`[domain].crt` file!

### Verify the certificate

Wait for chef to converge, or force a convergence.

Use a tool such as <https://www.sslshopper.com/ssl-checker.html> to verify that
the certificate is live, working, and fully valid.

## Monitoring

We utilize prometheus blackbox to regularly check endpoints and send us alerts
when those endpoints go down as well as validate and alert us at a threshold
when those certificates are going to expire.

* https://gitlab.com/gitlab-com/runbooks/blob/master/rules/ssl-certificate-expirations.yml

## Notes

* Certificates that were setup via DNS approval now have their renewal automated
  after configuring [Route53 integration with SSLMate](https://sslmate.com/account/integrations/add/aws)

* For dev.gitlab.org we use the same certificate for registry so make sure you
  update the normal and registry certificates with the same one.

* SSLMate is configured to email the Production Engineering team 30 days prior
  to a certificate expiring and again at regular intervals until the cert is
  replaced or expired.

* SSLMate is configured to monitor the following domains for certificates that
  are issued outside of SSLMate control and alert Production Engineering:
  * gitlab.com
  * gitlab.org
  * gitlab.net
  * gitlab.io
  * gitlap.com

[SSLMate]: https://sslmate.com/

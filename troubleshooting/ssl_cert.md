# SSL Certificate expiring or expired

## First and foremost

*Don't Panic*

## Symptoms

You see alerts like

```
@channel about.gitlab.com HTTP SSL Certificate WARNING - Certificate 'about.gitlab.com' will expire on Thu Nov 30 23:59:00 2016
```

## Possible checks

Check with browser if this is really the case.

## Resolution

We use [SSLMate] for ordering SSL certificates. Get the commandline tool via
https://sslmate.com/help/install. If you're using Homebrew you can install it with `brew install sslmate`.

Credentials are in 1Password.

### Buy a new certificate

```
sslmate buy about.gitlab.com
```

When asked to prove authorization, select **Add a DNS record**, and add the
provided `CNAME` entry via Route 53. You can leave this `CNAME` record in the zone.

The `sslmate` client will download the key and certificate to the directory in
which the command was executed.

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
```

**Note:** You _must_ use the `[domain].chained.crt` certificate file, _not_ the
`[domain].crt` file!

### Verify the certificate

Use a tool such as <https://www.sslshopper.com/ssl-checker.html> to verify that
the certificate is live, working, and fully valid.

## Notes

* For dev.gitlab.org we use the same certificate for registry so make sure you
  update the normal and registry certificates with the same one.

[SSLMate]: https://sslmate.com/

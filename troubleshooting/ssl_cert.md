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

We use sslmate for ordering SSL certificates, get the commandline tool via https://sslmate.com/help/install.

Credentials are in 1password.

### Buy a new certificate
```
sslmate buy about.gitlab.com
```

### Use rake to update vault
Since we store the certificate or at least the key always in a vault, update it with the new certificate and key.
```
cd chef-repo/
rake edit_role_secrets[the_role_with_vault]
```

## NOTES
* For dev.gitlab.org we use the same certificate for registry so make sure you update the normal and registry certificates with the same one.

# SSL Certificate expiring or expired

## Symptoms

You see alerts like

```
@channel about.gitlab.com HTTP SSL Certificate WARNING - Certificate 'about.gitlab.com' will expire on Thu Nov 30 23:59:00 2016
```

## Possible checks

Check with browser if this is really the case.

From your terminal, you can display additional details for a certificate using:

```
echo | openssl s_client -showcerts -servername my.hostname.com -connect my.hostname.com:443 2>/dev/null | openssl x509 -inform pem -noout -text
```

If you are only interested in the expiration date, you can use:

```
echo | openssl s_client -showcerts -servername my.hostname.com -connect my.hostname.com:443 2>/dev/null | openssl x509 -inform pem -noout -text | grep -A2 Validity
```

## Resolution

Purchase a new certificate. [Documentation here.](../howto/ssl_cert.md)

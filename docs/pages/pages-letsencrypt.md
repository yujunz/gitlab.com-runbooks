# Troubleshooting LetsEncrypt for Pages

In GitLab Pages, you can turn on the use of LetsEncrypt (LE) to provide the TLS certificate, per domain.  When this is on, GitLab takes care of talking ACME to LetsEncrypt to initially generate, and later renew, certificates for the Pages domain.

It has been observed that this may fail, and the logging is somewhere between negligible and non-existent.

Some hints for ways to debug and possibly fix this follow.  All code below is rails-console snippets.

The renewals are done every 10 minutes by cron job, but there are multiple steps between requesting, validating, and deploying, so it can take 20-30 minutes from when the process begins to when it is deployed.

## Viewing domains that GitLab is trying to generate/renew

```
PagesDomain.need_auto_ssl_renewal.find_each do |domain|
  puts "#{domain.id} #{domain.domain}"
end
```

If your domain isn't in this list, then GitLab thinks it either has a cert from LE already, or has a user-supplied cert.  Either way, LE is not the problem here.

## Getting the status of the request
From the previous (or other information), get the ID of the domain you're working on.

```
pd = PagesDomain.find(<ID>)
pd.acme_orders
```
Should show only one order (usually), with plausible looking dates.  If there are no orders, then that's weird, and the cron job should pick this up in about 10 minutes and start the process

```
pd.acme_orders.expired
```
Should be an empty array [].  If it is, then the single order above is the active one.  If it contains the above order, then it will be removed at the next cron job run

```
acme_order = ro.acme_orders.first
api_order = ::Gitlab::LetsEncrypt::Client.new.load_order(acme_order.url)
api_order.status
```
Status maps to statuses in https://ietf-wg-acme.github.io/acme/draft-ietf-acme-acme.html#status-changes

"pending" means that we have received the challenge (probably), but haven't told ACME that we're ready for verification.  This can be triggered with:
```
ao = api_order.send(:acme_order)
authorization = ao.authorizations.first
challenge = authorization.http
challenge.request_validation
```

Other states like 'valid' and 'ready' are good, and indicate that everything is proceeding; the regular processing should pick up the certificate and update gitlab-pages soon (10-20 minutes)

## Forcing a cron run

If you don't want to wait, you can push through processing of this domain with:
```
::PagesDomains::ObtainLetsEncryptCertificateService.new(pd).execute
```

Not sure what would happen if you did it when the real cron job was running, but it is possible bad, so steer clear of 10-minute boundaries.

NB: something needs to change the contents of .update file in pages-root (`/var/opt/gitlab/gitlab-rails/shared/pages`) for gitlab-pages to reload the config.json file.  This should happen automatically and quickly, but sometimes it doesn't (don't know why yet).  Check the date on it, and wait till it changes.  Once it does, the new cert should be picked up.

## Other failure modes
Please document them if you find them.

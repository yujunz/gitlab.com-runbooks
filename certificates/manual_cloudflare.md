## Manual Cloudflare Certificates

### Replacement

1. Obtain the new certificate from [SSMLate](https://sslmate.com/console/orders/).
   - *You will not be able to obtain a backup from via GCP!*
1. Get the current private key from the `SSLCerts Lockbox` 1Password vault and save it to your machine. (preferably on a tmpfs)
   - Alternatively for a certificate that is available in GKMS, you can retireve it there, too.
1. Log into https://dash.cloudflare.com and select the zone, to which the certificate is matched. (e.g. staging.gitlab.com for a certificate which matches that SAN)
   - When prompted for an account, select `GitLab`.
1. Click on the `SSL/TLS`-tab and `Edge Certificates`.
1. Select the certificate you would like to replace by clicking on the `Manage` button for that certificate followed by the wrench icon.
   - Its type should be `Custom` or `Custom (legacy)`, others are managed by Cloudflare and cannot manually be replaced!
1. Paste the TLS Certificate into the `SSL Certificate` field and the private key into the `Private Key` field.
   - Select the `Bundle Method` `Compatible`
   - Select `Private Key Restriction` `Distribute to all Cloudflare data centers`
   - Set `Legacy Client Support` to `Modern`
1. Click `Upload Custom Certificate`
1. Close the management dialog that might still be open and refresh the page.
1. You should now see the updated certificate.

### Rollback

There is no backup mechanism provided. So a rollback would be a replacement with a prior version of the certificate. That might exist in the `SSLCerts Lockbox` history.

## GCP Load Balancer

### Replacement

1. Obtain the new certificate from [SSMLate](https://sslmate.com/console/orders/).
   - *You will not be able to obtain a backup from via GCP!*
1. Get the current private key from the `SSLCerts Lockbox` 1Password vault and save it to your machine. (preferrably on a tmpfs)
1. Determine the expiration date of the new certificate: `< certificate.pem openssl x509 -noout -text | grep 'Not After'`
1. Upload the certificate (chain) and private key from your local machine:

   ```
   gcloud --project=${project} compute ssl-certificates create ${CN}-exp-${EXP_DATE_ISO8601} --certificate certificate.pem --private-key key.pem
   ```

   - Replace any periods (`.`) with dashes (`-`).
   - For wildcards certificates (e.g. `*.ops.gitlab.net`) use `wildcard-ops-gitlab-net` etc.
   - The expiration date should be formatted in ISO8601 (e.g. `2019-12-31`) and converted to UTC if necessary.

1. The certificate will then be available at the following resource route:
   `projects/${project}/global/sslCertificates/${certificate}` (you may have to specify that resource path to the relevant terraform module).
1. Edit the terraform for the LB to point at the new certificate, as seen in [this example](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/merge_requests/935).
   1. It might help to do a string replace. To find old certificates in the project run `gcloud --project=${project} compute ssl-certificates list`
1. Once applied, it may take 10 minutes or longer for your changes to be seen live.

### Cleanup

###### Validate the new certificate is working before doing this!
1. Delete the old cert from GCP, to de-clutter: `gcloud --project=gitlab-ops compute ssl-certificates delete wildcard-ops-gitlab-net`
1. Delete the private key (and cert) from your local machine.

### Rollback

If you did not clean up:

1. Revert the Merge Request for Terraform changes
1. Apply it and wait.

If you already cleaned up and did *not* re-key the certificate:

1. Go to https://crt.sh/?q=*.ops.gitlab.net (replacing the query with the CN of the certificate you are looking for)
1. copy the `crt.sh ID` for the old certificate (check via the expiration date)
1. Visit `https://crt.sh/?d=<ID you copied>` to retrieve a copy of the leaf certificate.
1. Get the required certificate chain.
   1. Open `https://crt.sh/?id=<ID you copied>`
   1. Scroll down and you should see the certificate contents
   1. Click on `Issuer: (CA ID: xxxx)`
   1. In the `Certificates` list click on the first `crt.sh ID`
   1. click on `Download Certificate: PEM` to get the intermediate certificate.
   1. Repeat until you see a `Root` CA in the `Certificates` list. This means you reached the root of trust.
1. Combine all the above certificates into one PEM.
1. Use this PEM as the rollback certificate.

If you already cleaned up and *did* re-key the certificate.

1. You're out of luck. Depending on what the issue is, you might try:
  1. Re-installing the new certificate.
  1. Re-keying again
  1. Getting a Certificate from a new CA.

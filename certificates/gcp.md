## GCP Load Balancer

GCP provides [automatic SSL Certificates](https://cloud.google.com/load-balancing/docs/ssl-certificates/google-managed-certs). Where possible, we use this feature to automatically generate and renew certs.

For legacy certs, or services behind a CDN, there is a manual procedure for updating them.

### Google-managed certificates

GCP load balancers support automatic provisioning and renewal of free
certificates backed by Let's Encrypt.

#### Kubernetes

Load balancers provisioned by GKE's ingress controller (ingress-gce) can be
instructed to provision Google-managed certificates by creating a
ManagedCertificate resource and binding it to an Ingress with an annotation. See
[docs](https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs) for
details.

If migrating from a non-Google-managed certificate, you must ensure that both
the new managed and old self-managed certificate continue to be served by the
Load balancer's frontend to avoid downtime. This is done in 2 phases:

1. Create a ManagedCertificate and bind it to an Ingress that already has
   `Ingress.spec.tls` configured.
1. In the GCP console, you should see a "PROVISIONING" managed cert, in addition
   to the existing certificate.
1. Eventually, the cert will finish provisioning, and some time later, the LB
   will switch to serving the new cert with zero downtime. This can take up to
   30 minutes.
1. You can now remove `Ingress.spec.tls` in a subsequent deployment.

See [migration docs](https://cloud.google.com/load-balancing/docs/ssl-certificates/google-managed-certs#replace-ssl).

Example:

- Managed certificate provisioning in a Helm chart:
  https://gitlab.com/gitlab-org/charts/plantuml/-/merge_requests/17
- That same helm chart being used to provision a new managed cert, without
  removing the custom one:
  https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/merge_requests/193
- Finally, removing the custom certificate (`Ingress.spec.tls` is what is being
  manipulated by Helm):
  https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/merge_requests/194

#### Terraform

Create a [`google_compute_managed_ssl_certificate`](https://www.terraform.io/docs/providers/google/r/compute_managed_ssl_certificate.html),
and bind it to a [`google_compute_target_https_proxy`](https://www.terraform.io/docs/providers/google/r/compute_target_https_proxy.html)
(or the analogous resource for TCP load balancing).

When migrating from a self-managed cert to a managed one, you must not remove
the old certificate from the
`google_compute_target_https_proxy.ssl_certificates` array until the new
certificate is done provisioning, and the LB has switched over to serving the
new certificate. This can take up to 30 minutes.

See [migration docs](https://cloud.google.com/load-balancing/docs/ssl-certificates/google-managed-certs#replace-ssl).

This will likely have to be orchestrated through our terraform modules. For an
example of cutting over to a new managed cert with zero downtime without making
successive, and possibly breaking, module changes, see the following manual
interventions and MRs:

- https://gitlab.com/gitlab-com/gl-infra/production/-/issues/2238
- https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/merge_requests/1771
- https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/google/https-lb/-/merge_requests/7
  (although note that this contains a small error that was fixed in a follow-on:
  Google doesn't like trailing-dot FQDNs in this context).

### Replacement of non-Google-managed certificates

1. Obtain the new certificate from [SSMLate](https://sslmate.com/console/orders/).
   - *You will not be able to obtain a backup from via GCP!*
1. Get the current private key from the `SSLCerts Lockbox` 1Password vault and save it to your machine. (preferably on a tmpfs)
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

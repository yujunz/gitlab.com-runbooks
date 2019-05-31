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

### Process to update certificates in production

#### Preparation for update
1. The newly renewed certificate has been downloaded with sslmate.
 * ```sslmate download example.com```
1. The proper fields to be updated in the GKMS vaults are identified and the old cert is verified to match the new one. You will need to locate the right vaults (chances are it's one of the two in the commands listed here). In the chef-repo, run these commands to look for certs:
  * ```./bin/gkms-vault-show frontend-loadbalancer gprd```
  * ```./bin/gkms-vault-show gitlab-omnibus-secrets gprd```
1. A backup copy of the old certificate field is stored locally. You may need to replace it if you run into trouble.
1. A properly formatted version of the new cert is already made and formatted for JSON. This makes it easier for updating json cert fields.
  * ```awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' example.com.chained.crt > json.example.com.cert```
1. Confirm using a knife command that the hosts you'll target are the ones you expect: `knife search -i node 'roles:<role name> AND chef_environment:<env name>'`
1. If you are updating the internal ```*.gprd.gitlab.net``` certificate, be aware that there are extra steps required in the google console to update a load balancer certificate.

#### Execution of the update
1. Check the state of chef-client: `knife ssh "roles:<role name> AND chef_environment:<env name>" "ps -aux | grep chef-client | grep -v grep"`
1. Stop chef on the haproxy fleet that serves the cert in question.
  * ```knife ssh "role:<role name>" "sudo service chef-client stop"```
1. Edit the vaults that contain the cert using comands like this:
  * ```./bin/gkms-vault-edit frontend-loadbalancer gprd```
  * ```./bin/gkms-vault-edit gitlab-omnibus-secrets gprd```
1. Find and replace the cert field identified earlier in the JSON and save the changes. Document in the issue the specific fields you are updating.
1. Inspect changes that would be applied on one of the nodes: `sudo chef-client --why-run`
1. Force a chef-run on one of the nodes for verification. You should be able to simply run ```sudo chef-client``` and see the updated certificate in the output.
1. Use openssl to verify the correct certificate is in place:
  * ```echo | openssl s_client -connect <NODE IP ADDRESS>:443 -servername <HOSTNAME> 2>/dev/null | openssl x509 -noout -dates```
1. (if it's a web based service) Use your web browser to verify the certificate
  * edit `/etc/hosts` on your laptop and add an overwrite for the hostname of your service
  * in your browser, go to the hostname of your service
  * make sure you don't get any errors, e.g. about intermediate certs missing, and that you can see the new expiry date
1. Restart chef on the nodes from the first step.
  * ```knife ssh "role:gprd-base-lb-fe" "sudo service chef-client start"```

#### Extra steps for GCP certificate updates
1. Under ```Networking -> Network services -> Load balancing``` switch to the advanced menu.
1. Select the certificates label and create a new SSL certificate using the private key from the GKMS vaults, and the information downloaded from SSLMate.
1. Edit the frontend rules for the load balancer you are updating and change it's certificate to the one you added and make sure you save your changes.
1. ***It may take 10 minutes or longer for your changes to be seen live.***

#### Rollback steps
1. Revert changes made to the vaults using the ```gkms-vault-edit``` command.
1. Replace the changed cert with the backup that was made locally.
1. Save the changes and force a chef run on the test system and verify it is fixed (or back to normal).

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

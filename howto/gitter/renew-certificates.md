# How to renew the TLS certificate for `*.gitter.im`

There are three points where Gitter serves TLS traffic:

1. ELBs
1. CloudFront
1. Websockets servers

The latter because ELBs don't support websockets traffic hence we just use a TCP listener and terminate the TLS session on the nodes.

First thing you should do is -unsurprisingly- [renew the certificate](https://gitlab.com/gitlab-com/runbooks/blob/master/troubleshooting/ssl_cert.md). SSLMate will download the certificates in the current directory. Keep them there for now. Note: having more than one AWS account configured on your profile may confuse SSLMate. If you can't see the new Route53 record configured on the correct zone you should find out where it got created (it's an `NS` type) and create it manually where it should be.

## ELBs and CloudFront

1. Upload the certificate to AWS. **Important:** do NOT use the pop-up dialog on the ELB page: it will add the cert to / and CloudFront won't be able to see it. Use this command instead (change the name of course):
```
aws iam upload-server-certificate \
  --server-certificate-name STAR.gitter.im_2017-11-15 \
  --certificate-body 'file://*.gitter.im.crt' \
  --private-key 'file://*.gitter.im.key' \
  --certificate-chain 'file://*.gitter.im.chain.crt' \
  --path /cloudfront/gitter-production/
```

1. Start rolling out to the ELBs. It's better to start with a small service like `irc.gitter.im` on port 6667 (running behind the `apps-servers-elb-prod` ELB at the time of this writing). Run `openssl s_client -connect irc.gitter.im:6667` before and after the change to verify that the new certificate has been successfully rolled out. If everything is OK then move on to the rest of the services.

1. Move on to CloudFront. Update the certificate for all the relevant distributions to the new one. If you're unsure you can load the CloudFront page on the AWS console, open each distribution in a new tab, click on "Edit" under the "General" tab and check out the certificate.
1. Verify that all the distributions are aligned. Here's a handy script that you can use:
```
for i in $(aws cloudfront list-distributions --query 'DistributionList.Items[].Id' --output text)
do
  echo -n "$i "
  aws cloudfront get-distribution-config --id $i --query 'DistributionConfig.ViewerCertificate.IAMCertificateId'
done
```

## Websockets servers

1. Set a maintenance on Pagerduty for the `monit-prod-critical` service.

1. Update the MD5 fingerprint in the monit checks. You can find them by running `grep -r certmd5 *` in the ansible directory. You can compute the new fingerprint with the following command:
```
openssl x509 -fingerprint -md5 -in '*.gitter.im.crt' | head -1 | cut -f2 -d '=' | tr -d :
```

1. Update the certificate and the key in Ansible. The certificate is in `roles/gitter/certs/files/certs/gitter.crt` while the key is an Ansible vault located in `ansible/roles/gitter/certs/vars/main.yml`.

1. Test the roll out on a single node:
```
ansible-playbook -i prod -l ws-01.prod.gitter --check -t certs playbooks/gitter.yml
```

1. Roll out to one node:
```
ansible-playbook -i prod -l ws-01.prod.gitter -t certs playbooks/gitter.yml
```

1. Reload nginx and verify that it's serving the new certificate:
```
sudo nginx -s reload
openssl s_client -connect localhost:443
```

1. Roll out to the rest of the nodes. You'll notice that it'll be rolled out to the webapp servers as well. This is expected.
```
ansible-playbook -i prod -t certs playbooks/gitter.yml
```

1. Reload nginx on all other nodes.

1. Verify, verify, verify.

1. Delete the local certificate/key/chain.

1. You're done.

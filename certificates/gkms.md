## GKMS

### Automation

This process should be automated via the [Certificates Updater](https://gitlab.com/gitlab-com/gl-infra/certificates-updater). In cases where this should not be the case, you can follow the instructions below.

### Replacement

Make sure you know the item (e.g. `frontend-loadbalancer gprd`) and fields (if they differ from `ssl_certificate` and `ssl_key`). Refer to the certificate table for that information.

- Obtain the new certificate from [SSMLate](https://sslmate.com/console/orders/).

- Create a local backup of the gkms-vault, by executing
```bash
./bin/gkms-vault-show ${item} > ${item}_bak.json
```

- Format the new certificate (and/or key) to fit into json properly and copy the output to the clipboard. (The following command is executed with GNU sed)
```bash
sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g' ${new_certificate}.pem
```

- Update the values in the gkms-vault. Make sure to only edit the fields that were specified. Some data bags will contain multiple certificates!
```bash
./bin/gkms-vault-edit ${item}
```

- This should give you an error if the new gkms-vault is not proper json. Still you should validate that by running `./bin/gkms-vault-show ${item} | jq .`. If that runs successfully, you have successfully replaced the certificate! Congratulations!

- Finally trigger a chef-run on the affected node(s). This should happen automatically after a few minutes, but it is recommended to observe one chef-run manually.

### Rollback of a replacement

Sometimes stuff goes wrong. Good thing we made a backup! :)

- Copy the contents of `${item}_bak.json` into your clipboard

- Update the values in the gkms-vault. Clear out the whole write-buffer and paste the json you just copied.
```bash
knife vault edit ${data_bag} ${item}
```

- Done!

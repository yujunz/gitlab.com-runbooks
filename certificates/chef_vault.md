## Chef Vault

### Replacement

Make sure you know the data bag (e.g. `about-gitlab-com`) item (e.g. `_default`) and eventual fields (if they differ from `ssl_certificate` and `ssl_key`). Refer to the certificate table for that information.

- Obtain the new certificate from [SSMLate](https://sslmate.com/console/orders/).

- Create a local backup of the databag, by executing
```bash
knife vault show -Fj ${data_bag} ${item} > ${data_bag}_bak.json
```

- Format the new certificate (and/or key) to fit into json properly and copy the output to the clipboard. (The following command is executed with GNU sed)
```bash
sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g' ${new_certificate}.pem
```

- Update the values in the data bag. Make sure to only edit the fields that were specified. Some data bags will contain multiple certificates!
```bash
knife vault edit ${data_bag} ${item}
```

- This should give you an error if the new data bag is not proper json. Still you should validate that by running `knife vault show -Fj ${data_bag} ${item} | jq .`. If that runs successfully, you have successfully replaced the certificate! Congratulations!

- Finally trigger a chef-run on the affected node(s). This should happen automatically after a few minutes, but it is recommended to observe one chef-run manually.

### Rollback of a replacement

Sometimes stuff goes wrong. Good thing we made a backup! :)

- Copy the contents of `${data_bag}_bak.json` into your clipboard

- Update the values in the data bag. Clear out the whole write-buffer and paste the json you just copied.
```bash
knife vault edit ${data_bag} ${item}
```

- Done!

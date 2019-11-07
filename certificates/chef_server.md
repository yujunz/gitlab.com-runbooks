## Chef Server

### Replacement

- Obtain the new certificate from [SSMLate](https://sslmate.com/console/orders/).
- ssh to `chef.gitlab.com`
- Create backup of the certificate (replacing 2019 with whatever year the old certificate started in)
```bash
sudo cp /etc/ssl/chef.gitlab.com.crt{,.2019}
```
- Copy the new certificate to the server as `/etc/ssl/chef.gitlab.com.crt` and change the permissions to `400` and owner to `root:root`
- `sudo chef-server-ctl hup nginx`
- Done!

### Rollback of a replacement

Sometimes stuff goes wrong. Good thing we made a backup! :)

- move the new certificate in a safe place
- restore the old certificate by renaming or copying it back.
- `sudo chef-server-ctl hup nginx`
- Done!

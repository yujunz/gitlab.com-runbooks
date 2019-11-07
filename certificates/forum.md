## Forum / Discourse

### Replacement

- Obtain the new certificate from [SSMLate](https://sslmate.com/console/orders/).
- ssh to `forum.gitlab.com`
- Create backup of the certificate (replacing 2019 with whatever year the old certificate started in)
```bash
sudo cp /var/discourse/shared/standalone/ssl/ssl.crt{,.2019}
```
- Copy the new certificate to the server as `/var/discourse/shared/standalone/ssl/ssl.crt` and change the permissions to `544` and owner to `root:root`
- `sudo restart app` to restart discourse
- Done!

### Rollback of a replacement

Sometimes stuff goes wrong. Good thing we made a backup! :)

- move the new certificate in a safe place
- restore the old certificate by renaming or copying it back.
- `sudo restart app`
- Done!

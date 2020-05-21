# customers.gitlab.com

Overview: https://gitlab.com/gitlab-org/customers-gitlab-com/-/blob/staging/README.md

customers.gitlab.com is currently hosted in Azure with a plan to move it to
auto-devops in GCP https://gitlab.com/gitlab-org/customers-gitlab-com/-/issues/671

## API key rotation

GitLab.com and Staging.GitLab.com are configured with two environment variables:

* `SUBSCRIPTION_PORTAL_ADMIN_TOKEN`
* `CUSTOMER_PORTAL_URL`

Although it this token is called an ADMIN it has limited access.

The admin token can be rotated on the customers.gitlab.com rails console:


```
ssh customers.gitlab.com

$ gitlab-rails-console

irb> a = Admin.find_by_email('gl_com_api@gitlab.com')
irb> a.update(authentication_token: Devise.friendly_token.first(16))
irb> a.save
irb> a

```

The token is passed into the rails environment through gkms secrets, to update it:

```
./bin/gkms-vault-edit gitlab-omnibus-secrets {gprd,gstg}
```

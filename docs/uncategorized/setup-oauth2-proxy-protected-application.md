# Setup oauth2-proxy protection for web based application

This runbook  describes how to setup new application that is protected with `oauth2-proxy` which uses
https://dev.gitlab.org/ as access provider.

`oauth2-proxy` is a simple application that prepares a HTTP proxy to any web-based application
that doesn't have own access management mechanism. Using `oauh2-proxy` we can protect such application
from unauthorized access.

## Requirements

To configure new application with oauth2-proxy you need to:

- have admin access to https://dev.gitlab.org/,
- have write access to ops.gitlab.net/gitlab-cookbooks/chef-repo,
- have write access to chef.gitlab.com,
- have configured knife environment,
- have admin access to nodes where the application is deployed (with sudo access).

## Gather data

Before going further you need to gather some data, that will be then used in configuration
files:

- SSL key value (the block started with `-----BEGIN PRIVATE KEY-----`),
- SSL certificate value (the block started with `-----BEGIN CERTIFICATE-----`),
- `cookie_secret` value

  for a secure value, please execute: `python -c 'import os,base64; print base64.urlsafe_b64encode(os.urandom(16))'`,
- `client_id` value,
- `client_secret` value.

To get `client_id` and `client_secret` go to https://dev.gitlab.org/admin/applications and create a new application:
- set application's FQDN as `Name`,
- set redirect URL using application's FQDN and `/oauth2/callback` as path, e.g.
  `https://prometheus.gitlab.com/oauth2/callback`,
- don't select any checkbox for `Trusted` or `Scopes` sections.

After saving changes you'll get `Application Id` (which is the `client_id`'s value) and `Secret` (which is the
`client_secret`'s value).

## Configure role

Note, that `oauth2-proxy` contains data for a specific FQDN. If your role is realised by multiple
nodes, then you should prepare specific roles that extend the general one and that contain the
`oauth2-proxy` configuration. For these you should repeat steps described in [gather data](#gather-data) section
for each used FQDN.

When we have all roles created, we first need to prepare secrets for the role:

```bash
$ rake edit_role_secrets[specific_role_name,_default]
```

where the content is:

```json
{
  "gitlab-oauth2-proxy": {
    "client_id": "client_id_value",
    "client_secret": "client_secret_value",
    "cookie_secret": "cookie_secret_value",
    "nginx": {
      "ssl_certificate": "content_of_ssl_certificate",
      "ssl_key": "content_of_ssl_key"
    }
  }
}
```

Having this we can then edit the specific role itself:

```bash
$ rake edit_role[specific_role_name]
```

where we need update `"default_attributes"` hash with:

```json
"gitlab-oauth2-proxy": {
  "chef_vault": "specific_role_name",
  "upstream": "upstream_url",
  "redirect_url": "redirect_url",
  "cookie_name": "_oauth2_proxy_NAME",
  "nginx": {
    "enable": true,
    "fqdn": "fqdn"
  }
}
```

Notice that:
- `upstream` should be set to an internal URL accessible on the server, e.g. `http://127.0.0.1:9090/`,
- `redirect_url` should be set to the URL configured on https://dev.gitlab.org/admin/applications during
  [gather data](#gather-data) step, e.g. `https://prometheus.gitlab.com/oauth2/callback`,
- the `NAME` in `cookie_name`'s value should be set to something specific to that FQDN, e.g. `_oauth2_proxy_prometheus`,
- `fqdn` should contain only a domain name (without scheme, port or path parts that are present in URL) and be set
  to the FQDN under which the application is accessible, e.g. `prometheus.gitlab.com`.

The last step is to update `run_list` array of the specified role with `"recipe[gitlab-oauth2-proxy]"`:

```json
(...)
  "run_list": [
    "role[general_role_here]",
    "recipe[gitlab-oauth2-proxy]"
  ]
(...)
```

You will also need to open HTTP and HTTPS traffic in the firewall. You can consider adding this to the general
role definition:

```json
(...)
  "run_list": [
    (...)
    "role[firewall-http]",
    "role[firewall-https]"
  ]
(...)
```

When everything is configured you can run chef-client on all related nodes or wait until chef will automatically
update the configuration.

If you don't want to wait, you can execute:

```bash
$ knife ssh -C1 -aipaddress 'roles:general_role_here' -- sudo chef-client
```

This command will update chef managed configuration on all nodes connected to `general_role_here` role, in one-by-one
mode.


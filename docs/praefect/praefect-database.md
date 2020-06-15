# Praefect Database

The praefect database is a GCP CloudSQL PostgreSQL instance. On occasion it will
be necessary to connect to it interactively in a `psql` shell. As with all
manual database access, this should be kept to a minimum, and
frequently-requested information should be exposed as Prometheus metrics if
possible.

## Connect to the Praefect database

```
ssh YOURNAME-praefect-db@console-01-sv-gprd.c.gitlab-production.internal
```

This requires your chef user to have the `db-console-praefect` group (e.g.
https://ops.gitlab.net/gitlab-cookbooks/chef-repo/-/merge_requests/3703).

### Alternative method

This should only be followed if for whatever reason you can't use a
`db-console-praefect` chef user group.

1. Obtain the connection info
  1. Get the IP, database and user:

  ```
  knife node show praefect-01-stor-gprd.c.gitlab-production.internal -a omnibus-gitlab.gitlab_rb.praefect
  ```
  1. Get the password:

  ```
  <chef-repo>/bin/gkms-vault-show gitlab-omnibus-secrets gprd | jq '.["omnibus-gitlab"].gitlab_rb.praefect.database_password' -r
  ```
  1. Alternatively, obtain the connection info from one of its clients directly:


     ```
     ssh praefect-01-stor-gprd.c.gitlab-production.internal 'sudo cat /var/opt/gitlab/praefect/config.toml'
     ```
1. `ssh console-01-sv-gprd.c.gitlab-production.internal`
  1. On the console: `psql -h <DB IP> -U <DB user> -d <database>`
  1. Paste in the password when prompted.

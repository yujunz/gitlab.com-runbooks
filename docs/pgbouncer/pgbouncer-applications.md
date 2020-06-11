### Applications can not log into pgbouncer.

Pgbouncer does not know what users exist on the database. It accepts a new connection
and executes the query configured under `auth_query`
[in the cookbook](https://gitlab.com/gitlab-cookbooks/gitlab-pgbouncer/-/blob/67a9dc6e910c8c6efef1a4407a8b03b22083bb27/attributes/default.rb).
By default
this is: `SELECT username, password FROM public.pg_shadow_lookup($1)` for which it will
compare the credentials it received from the lookup with those it received from the
application. To run this query it uses the `auth_user` specified on the
`pgbouncer.ini`.

If an application can not log into the db via pgbouncer, there are two places to check:

1. pgbouncer logs: `/var/log/gitlab/pgbouncer/current` to find more information
1. postgres logs: `/var/log/gitlab/postgresql/current` on the database server. If the
user pgbouncer uses to perform this `auth_query` (by default `pgbouncer`), does not
have permissions, you will see errors here.

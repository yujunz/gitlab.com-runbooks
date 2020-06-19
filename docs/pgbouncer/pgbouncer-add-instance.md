# Add a new PgBouncer instance

Adding PgBouncer instances might be necessary for special tasks such as rolling
upgrades, or in case we reach organic saturation (for more details regarding
monitoring and troubleshooting of PgBouncer connections see [this
runbook](./pgbouncer-connections.md). For saturation spawning from abuse or
other incidents see [this runbook](./pgbouncer-saturation.md)). You'll ned to
take into consideration what kind of PgBouncer instance node you want to create:

## Adding a read/write PgBouncer node

Read/write nodes manage requests to the patroni cluster leader, and  are
deployed in their own VMs. There's two kind:

- General purpose PgBouncers ([terraform module
  `pgbouncer`](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/blob/021bcfc4d0c3fd425bdfc69ab2139a6033cdbfd2/environments/gprd/main.tf#L665-689))
- Sidekiq-specific PgBouncers([terraform module
  `pgbouncer-sidekiq`](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/blob/master/environments/gprd/main.tf#L713-737))

To add a new read/write node:

- Create a Merge Request on chef-repo to update the `pool_size` accordingly on
  `roles/gprd-base-db-pgbouncer.json` for general purpose PgBouncers, and/or on
  `roles/gprd-base-db-pgbouncer-sidekiq.json` for Sidekiq-specific PgBouncers
  (see [Preserving underlying connection
  count](#preserving-underlying-connection-count))
- Create a Merge Request on
  [gitlab-com-infrastructure](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/)
  that updates the `node_count` variable for the module you want to target.
- Merge and apply the chef-repo changes.
- Merge and apply the terraform changes.
- Wait for the node to be provisioned.
- Make sure that pgbouncer can establish connections to the primary database:
  ````
    $ sudo pgb-console
    pgbouncer=# SHOW STATS;
  ````
  You should see an entry for the `gitlabhq_production` database.
- Keep an eye on the node metrics at
  https://dashboards.gitlab.net/d/bd2Kl9Imk/host-stats?orgId=1&var-environment=gprd&var-node=pgbouncer-01-db-gprd.c.gitlab-production.internal&var-promethus=prometheus-01-inf-gprd
  (substitute `pgbouncer-01-db-gprd` for the name of your new node), and on the
  PgBouncer main dashboard
  https://dashboards.gitlab.net/d/pgbouncer-main/pgbouncer-overview?orgId=1

## Adding a read-only PgBouncer instance

Read-only PgBouncers live on the secondary patroni nodes. Adding additional
PgBouncer processes can be done via the chef-repo. You'll need to make the
following adjustments:

- On `roles/gprd-base-db-patroni.json`:
  - Add an additional port under `gitlab-pgbouncer.listening_ports`
  - Update the `pool_size` attribute accordingly (see [Preserving underlying
    connection count](#preserving-underlying-connection-count))
- On `roles/gprd-base-db-pgbouncer-common.json`:
  - Add the new systemd service under `gitlab-server.systemd_service_overrides`

See https://ops.gitlab.net/gitlab-cookbooks/chef-repo/-/merge_requests/2159 for
a reference MR (though notice that we don't need to do the prometheus changes
anymore).

- Merge and apply the chef-repo changes.
- Run chef-client on the targeted hosts.
- Make sure that pgbouncer can establish a connection to the secondary database:
  ````
    $ sudo pgb-console-[n]
    pgbouncer=# SHOW STATS;
  ````
  where `n` is the index corresponding to the ports you added on
  `gitlab-pgbouncer.listening_ports` (e.g. `pgb-console-3` if you added a fourth
  port). You should see an entry for the `gitlabhq_production` database. If you
  added multiple ports check the pgb-console for each of them.

## Preserving underlying connection count

Unless you intentionally want to increase the amount of underlying connections
to the database, you'll need to adjust the `pool_size` attribute in the relevant
chef-repo recipe to maintain the current settings. For example, if `pool_size`
for the specific type of PgBouncer you're creating is 40 and there's currently 3
PgBouncers, then the total amount of connections is 120. To add a 4th PgBouncer
while maintaining that amount, `pool_size` should be 30.

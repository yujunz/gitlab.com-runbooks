# Removing a PgBouncer instance

Removing PgBouncer instances might be necessary for conserving costs or simplifying setups.
You'll need to take into consideration what kind of PgBouncer instance node you want to remove:

## Removing a read/write PgBouncer node

Read/write nodes manage requests to the Patroni cluster leader, and  are
deployed in their own VMs. There's two kind:

- General-purpose PgBouncers ([terraform module
  `pgbouncer`](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/blob/021bcfc4d0c3fd425bdfc69ab2139a6033cdbfd2/environments/gprd/main.tf#L665-689))
- Sidekiq-specific PgBouncers([terraform module
  `pgbouncer-sidekiq`](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/blob/master/environments/gprd/main.tf#L713-737))

To remove a read/write node:

- Create a Merge Request on chef-repo to update the `pool_size` accordingly on
  `roles/gprd-base-db-pgbouncer.json` for general-purpose PgBouncers, and/or on
  `roles/gprd-base-db-pgbouncer-sidekiq.json` for Sidekiq-specific PgBouncers
  (see [Preserving underlying connection
  count](#preserving-underlying-connection-count))
- Remove the last _n_ (number of instances planned for removal) PgBouncer instances from their ILB,
  `gprd-pgbouncer-regional` for general-purpose PgBouncers and
  `gprd-pgbouncer-sidekiq-regional` for Sidekiq-specific PgBouncers.
  - This is required to avoid disrupting existing client connections to the DB primary.
  - It can take a quite a while for all clients to relinquish their DB connections, so plan ahead.
    - Alternatively, you can incrementally HUP/restart clients to speed up the process.
    - Use this one-liner to target clients connected to the to-be-removed instance.
      ```
      # Change hostname (first line) to to-be-removed instance
      # Change `hup puma` to `restart sidekiq-cluster` when removing a PgBouncer-specific instance
      ssh pgbouncer-03-db-gstg.c.gitlab-staging-1.internal \
        "sudo pgb-console -c 'SHOW CLIENTS' | grep 'gitlabhq_production' | awk '{print \$9}' | sort | uniq" | \
        xargs -P3 -L3 -I{} knife ssh ip:{} 'sudo gitlab-ctl hup puma'
      ```
- Create a Merge Request on
  [gitlab-com-infrastructure](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/)
  that updates the `node_count` variable for the module you want to target.
- Merge and apply the chef-repo changes.
- Merge and apply the terraform changes.
- Wait for the node to be de-provisioned.

## Removing a read-only PgBouncer instance

Read-only PgBouncers live on the secondary Patroni nodes. Removing PgBouncer
processes can be done via the chef-repo. You'll need to make the
following adjustments:

- On `roles/gprd-base-db-patroni.json`:
  - Remove a port or ports under `gitlab-pgbouncer.listening_ports`
  - Update the `pool_size` attribute accordingly (see [Preserving underlying
    connection count](#preserving-underlying-connection-count))
- On `roles/gprd-base-db-pgbouncer-common.json`:
  - Remove systemd service(s) under `gitlab-server.systemd_service_overrides`
    from the end of the list.
- Stop Chef across all Patroni nodes by running `knife ssh roles:gprd-base-db-patroni 'sudo chef-client-disable "Database maintenance issue prod#xyz"'
- Merge and apply the chef-repo changes.
- Put the Consul services to be removed in maintenance mode by running `consul maint -enable -service=db-replica-<n>`
  - For example, assuming there were 3 ports and only one is removed, then the service to disable is `db-replica-2` (service names are zero-indexed).
- Wait for the clients to drain from this particular PgBouncer instance by running and waiting for zero to be in the output:
  ```
  while true; do sudo pgb-console-2 -c 'SHOW CLIENTS;' | grep gitlabhq_production | cut -d '|' -f 2 | awk '{$1=$1};1' | grep -v gitlab-monitor | wc -l; sleep 5; done
  ```
- Enable Chef by running `sudo chef-client-enable` then run `chef-client` on the targeted hosts.

## Preserving underlying connection count

Unless you intentionally want to decrease the amount of underlying connections
to the database, you'll need to adjust the `pool_size` attribute in the relevant
chef-repo recipe to maintain the current settings. For example, if `pool_size`
for the specific type of PgBouncer you're removing is 30 and there's currently 4
PgBouncers, then the total amount of connections is 30 * 4 = 120. To remove the 4th PgBouncer
while maintaining that amount, `pool_size` should be 120 / 3 = 40.

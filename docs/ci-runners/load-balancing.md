# Database Load Balancing

GitLab.com uses database load balancing as supported by GitLab Enterprise
Edition: <https://docs.gitlab.com/ee/administration/database_load_balancing.html>.

Hosts to balance the load across are configured in Chef in the roles for each
cluster of workers (gitlab-fe-sidekiq, gitlab-fe-git, etc). The setting is
called `db_load_balancing` and specifies an array of secondary hosts to balance
the load across.

## Disabling Load Balancing

To disable load balancing you simply remove the hosts from the array, then
reload all Unicorn and Sidekiq processes. Reverting this requires doing the
inverse.

## Dealing With Replication Lag

The load balancer currently does not handle replication lag automatically. This
means that GitLab will continue using secondaries even if they're very far
behind. Not using secondaries automatically is something that we will add in the
future: <https://gitlab.com/gitlab-org/gitlab-ee/issues/2197>.

## Restarting Secondaries

In general it should be fine to restart a secondary without this immediately
introducing errors. Despite this it's best to announce such operations just in
case something goes wrong.

## Restarting The Primary

Restarting the primary can currently still lead to errors popping up due to the
vast number of places a query can be executed in the Rails application (handling
all this is rather tricky). Furthermore, a primary can take up to a minute to
come back online which may lead to Unicorn connection timeouts.

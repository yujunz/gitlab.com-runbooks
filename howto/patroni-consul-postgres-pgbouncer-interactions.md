## Table of Contents

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Quick orientation](#quick-orientation)
- [Where do the components run?](#where-do-the-components-run)
- [Links to external docs](#links-to-external-docs)
- [Quick reference commands](#quick-reference-commands)
  - [List of tools for working with these services](#list-of-tools-for-working-with-these-services)
  - [PgBouncer](#pgbouncer)
  - [Consul CLI](#consul-cli)
  - [Consul REST API: Commands to inspect/explore Patroni's state stored in Consul's key-value (KV) store](#consul-rest-api-commands-to-inspectexplore-patronis-state-stored-in-consuls-key-value-kv-store)
  - [Internal Loadbalancer (ILB)](#internal-loadbalancer-ilb)
- [Background details](#background-details)
  - [Purpose of each service](#purpose-of-each-service)
  - [Normal healthy interactions between these services](#normal-healthy-interactions-between-these-services)
- [Details of how Patroni uses Consul](#details-of-how-patroni-uses-consul)
  - [What is Patroni's purpose?](#what-is-patronis-purpose)
  - [What is Consul's purpose?](#what-is-consuls-purpose)
  - [How and why does Patroni interact with Consul as a datastore?](#how-and-why-does-patroni-interact-with-consul-as-a-datastore)
  - [What is the difference between the Patroni leader and the Consul leader?](#what-is-the-difference-between-the-patroni-leader-and-the-consul-leader)
  - [Why use one database (Consul) to manage another database (Postgres)?](#why-use-one-database-consul-to-manage-another-database-postgres)
  - [How does Consul balance consistency versus availability?](#how-does-consul-balance-consistency-versus-availability)
  - [How do Patroni's calls to Consul let it decide when to failover?](#how-do-patronis-calls-to-consul-let-it-decide-when-to-failover)
  - [What is Consul's `serfHealth` check, and how can it trigger a Patroni failover?](#what-is-consuls-serfhealth-check-and-how-can-it-trigger-a-patroni-failover)
  - [How does `serfHealth` work?](#how-does-serfhealth-work)
  - [What happens during a Patroni leader election?](#what-happens-during-a-patroni-leader-election)
  - [Define the relationship between Patroni settings `ttl`, `loop_wait`, and `retry_timeout`](#define-the-relationship-between-patroni-settings-ttl-loop_wait-and-retry_timeout)
  - [Why is Patroni's actual TTL half of its configured value?](#why-is-patronis-actual-ttl-half-of-its-configured-value)
- [Known failure modes](#known-failure-modes)
  - [What specific network paths can trigger Patroni failover if they become lossy?](#what-specific-network-paths-can-trigger-patroni-failover-if-they-become-lossy)
  - [Dedicated PgBouncer hosts can develop a very uneven distribution of client connections after maintenance or restart events](#dedicated-pgbouncer-hosts-can-develop-a-very-uneven-distribution-of-client-connections-after-maintenance-or-restart-events)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## Quick orientation

What are these services, and how do they work together?

Here is a brief summary of how Postgres database access is supported by Patroni, Consul, PgBouncer, and our Rails app:
* Postgres is our relational database.
  * Currently we have 1 writable primary instance and several read-only replica instances of Postgres.
  * The replica dbs handle read-only queries and act as failover candidates in case the primary db becomes unavailable (e.g. unreachable, unresponsive) or concerned about possible split-brain (e.g. unable to see/update Patroni cluster state).
* Patroni coordinates failover when the primary Postgres instance becomes unavailable.
  * Patroni stores its cluster state in Consul.
  * A Patroni agent runs on each Postgres host, monitoring that local Postgres instance and interacting with Consul to check cluster state and publish its own state.
* Database clients (Rails, Sidekiq, etc.) discover Postgres through Consul service discovery and access it through PgBouncer (a connection pooler).
  * PgBouncer is a connection pooling proxy in front of Postgres.  Having thousands of clients connected directly to Postgres causes significant performance overhead.  To avoid this penalty, PgBouncer dynamically maps thousands of client connections to a few hundred db sessions.
  * Consul advertises each PgBouncer instance as a proxy for a corresponding Postgres instance.
  * Because PgBouncer itself is single-threaded and CPU-bound, it can use at most 1 vCPU, so we run multiple PgBouncer instances in front of each Postgres instance to avoid CPU starvation.
  * Database clients discover the IP+port of the available PgBouncer instances by sending DNS queries to a local Consul agent.
* Currently we use dedicated PgBouncer VMs for accessing the primary db, rather than local PgBouncer processes on the db host (as we do for the replica dbs).
  * The primary db gets more traffic than any one replica db.
  * PgBouncer appears to be more CPU-efficient on dedicated VMs than when running on the primary db host.  We have a couple untested hypotheses as to why.
  * The primary db's PgBouncer VMs share a virtual IP address (a Google TCP Internal Load Balancer VIP).  That ILB VIP is what Consul advertises to database clients as the primary db IP.

See [here](#background-details) and [here](#details-of-how-patroni-uses-consul) for more details on the purpose, behaviors, and interactions of each service.


## Where do the components run?

| Service/component                 | Chef role                                 | Hostname pattern            | Port (Protocol)                                                       |
| --------------------------------- | ----------------------------------------- | --------------------------- | --------------------------------------------------------------------- |
| Postgres                          | gprd-base-db-patroni                      | patroni-{01..NN}-db-gprd    | 5432 (Pgsql)                                                          |
| PgBouncer for primary db          | gprd-base-db-pgbouncer                    | pgbouncer-{01..NN}-db-gprd  | 6432 (Pgsql)                                                          |
| PgBouncer for replica dbs         | Same as Postgres                          | Same as Postgres            | 6432 (Pgsql), 6433 (Pgsql)                                            |
| Patroni agent                     | Same as Postgres                          | Same as Postgres            | 8009 (REST)                                                           |
| Consul agent                      | gprd-base (recipe `gitlab_consul::agent`) | Nearly all Chef-managed VMs | 8600 (DNS), 8500 (REST), 8301 (Serf LAN)                              |
| Consul server                     | gprd-infra-consul                         | consul-{01..NN}-inf-gprd    | 8600 (DNS), 8500 (REST), 8301 (Serf LAN), 8302 (Serf WAN), 8300 (RPC) |

In addition to the above Chef-managed services, we use a [Google TCP Internal Loadbalancer (ILB)](https://cloud.google.com/load-balancing/docs/internal/)
to provide a single virtual IP address for the pool of PgBouncer instances for the primary db.  This allows clients to treat a pool of PgBouncers as a single endpoint.

Notes about the ILB:
* A Google TCP/UDP Internal Loadbalancer (ILB) is *not* an inline device in the network path.
* Instead, ILB is part of the control plane of the software defined network within a single geographic region.
* All backends (i.e. PgBouncer VMs) share the IP address of the ILB's forwarding rule, and within the VPC network, each TCP/UDP connection is routed to one of those backends.
* Backend instances contact the metadata server (metadata.google.internal) to generate local routes to accept traffic for the ILB's IP address.


## Links to external docs

* [Postgres docs](https://www.postgresql.org/docs/current/index.html) (remember to choose the appropriate version)
* [PgBouncer docs](https://www.pgbouncer.org/faq.html)
* Patroni:
  * [Top-level docs](https://patroni.readthedocs.io/en/latest/)
  * [Explanation of static versus dynamic config settings](https://patroni.readthedocs.io/en/latest/dynamic_configuration.html)
  * [List of all config settings](https://patroni.readthedocs.io/en/latest/SETTINGS.html)
* Consul:
  * [Consul CLI commands](https://www.consul.io/docs/commands/index.html)
  * [Consul Glossary](https://www.consul.io/docs/glossary.html)
  * [Consul Internals](https://www.consul.io/docs/internals/index.html)
* [Google TCP/UDP Internal Loadbalancer (ILB)](https://cloud.google.com/load-balancing/docs/internal/)
  * [List of our load balancers in GCP console web UI](https://console.cloud.google.com/net-services/loadbalancing/loadBalancers/list)


## Quick reference commands


### List of tools for working with these services

* `gitlab-psql`: Wrapper for generic `psql`, authenticating and connecting to the local Postgres instance as a superuser.
* `gitlab-patronictl`: Wrapper for generic `patronictl`, authenticating and connecting to the local Patroni agent.
* `pgb-console`, `pgb-console-1`, `pgb-console-2`: Wrapper for generic `psql`, authenticating and connecting to each of the local PgBouncer instances on their distinctive ports.  This allows running [PgBouncer's Admin Console commands](https://www.pgbouncer.org/usage.html#admin-console) like `SHOW HELP`, `SHOW STATS`, `RELOAD`, etc.
* `consul`: Consul CLI tool, for querying or modifying Consul from any host running a Consul agent.


### PgBouncer

All Patroni hosts are running local PgBouncer instances, including whichever host is currently the Patroni leader and primary Postgres db.  The PgBouncers on the primary db are idle, since we route its traffic through the dedicated PgBouncer hosts.

The same `pgb-console` script exists on the dedicated PgBouncer hosts used for routing traffic to the primary db.

**Note:** The mechanism for taking a PgBouncer out of service for maintenance is different for dedicated PgBouncer hosts than for a PgBouncer instance on a Patroni host.

List the PgBouncer processes.

```shell
$ pgrep -a -f '/usr/local/bin/pgbouncer'

$ pgrep -f '/usr/local/bin/pgbouncer' | xargs -r ps uwf
```

Each PgBouncer runs on a different TCP port and has its own script to connect to its Admin Console.

```shell
$ ls -1 /usr/local/bin/pgb-console*
/usr/local/bin/pgb-console
/usr/local/bin/pgb-console-1
/usr/local/bin/pgb-console-2
```

Connect to Admin Console for each of the PgBouncer instances.  This puts you in an interactive `psql` session, where you can run [PgBouncer commands](https://www.pgbouncer.org/usage.html#admin-console) like `SHOW HELP`, `SHOW POOLS`, `SHOW CLIENTS`, `SHOW SERVERS`, etc.

**Note:** You can also use any `psql` options on the command-line or psql meta-commands in the interactive shell (e.g. `\pset pager off`, `\x`).

```shell
$ sudo pgb-console
$ sudo pgb-console-1
$ sudo pgb-console-2
```

In an interactive session, show the PgBouncer configuration (`conffile`, `listen_port`, `max_client_conn`, `client_idle_timeout`, `server_lifetime`, `server_reset_query`, etc.).

```shell
pgbouncer=# SHOW CONFIG ;
```

For each PgBouncer instance, show a summary of each connection pool, including:
* `cl_active`: number of clients that are linked to a db server connection and can process queries
* `cl_waiting`: number of clients who have sent queries but are waiting for a db server connection to become available
* `sv_active`: number of db server connections linked to a client
* `sv_idle`: number of db server connections that are unused and immediately available for clients
* `sv_used` (unintuitive): number of db server connections that have been idle for more than `server_check_delay`, so they need `server_check_query` to run on them before they can be used again

```shell
$ for console in /usr/local/bin/pgb-console* ; do sudo $console -c 'SHOW POOLS' | cat ; done
```

For each PgBouncer instance, list the configured databases and their pool size limits.

```shell
$ for console in /usr/local/bin/pgb-console* ; do sudo $console -c 'SHOW DATABASES' | cat ; done
```

List connections from each PgBouncer instance to the local Postgres database instance.

```shell
$ for console in /usr/local/bin/pgb-console* ; do sudo $console -c 'SHOW SERVERS' | cat ; done
```

List connections from clients to each PgBouncer instance.

```shell
$ for console in /usr/local/bin/pgb-console* ; do sudo $console -c 'SHOW CLIENTS' | cat ; done
```

### Consul CLI

Consul queries and operations can mostly be done via either the `consul` CLI tool or the consul agent's HTTP REST interface (TCP port 8500).
All of these Consul queries can be run from *any* host running a Consul agent in the environment you want to inspect (e.g. `gprd`, `gstg`, etc.).
It does not have to be a Patroni host, because all Consul agents participating in the same gossip membership list can also make RPC calls to the Consul servers.

Get help with the `consul` CLI tool's commands and subcommands.

```shell
$ consul help
$ consul operator --help
$ consul kv --help
$ consul kv get --help
```

Summarize generic status info for the local host's Consul agent.

```shell
$ consul info
```

Tail the logs from the consul agent.  Ctrl-C to stop following.

```shell
$ consul monitor
```

Show the list of Consul servers, and indicate which one is currently the Consul leader.

```shell
$ consul operator raft list-peers
```

Show all KV records, including their metadata and base64-encoded values.

```shell
$ consul kv export
```

List all key names in the KV store.

```shell
$ consul kv export | jq '.[].key'
```

Show the values of all keys having prefix "service/pg-ha-cluster".  Output values are automatically decoded from base64.

```shell
$ consul kv get -recurse 'service/pg-ha-cluster'
```

Show a single KV record's value, with and without metadata.  Many of Patroni's KV record values are JSON, so piping the raw value to `jq` is sometimes more readable.

```shell
$ consul kv get -detailed 'service/pg-ha-cluster/config'
$ consul kv get 'service/pg-ha-cluster/config'
$ consul kv get 'service/pg-ha-cluster/config' | jq
```

Show the latest Patroni state self-published by each Patroni node through its Consul agent.

```shell
$ consul kv get -recurse -keys 'service/pg-ha-cluster/members/' | xargs -i consul kv get {} | jq -S
```

List all nodes running a Consul agent in this environment.

**Note:** Currently we run all Consul agents as though they were in the same datacenter (i.e. the same "Serf LAN").  Consul expects each "datacenter" to have its own set of Consul servers, with loose coupling between datacenters.  But the Consul servers in each datacenter would maintain state separately.  If we used "Serf WAN" to connect multiple regions, this command's output would only include Consul agents in this host's region (i.e. the Consul agents bound to this region's set of Consul servers).

```shell
$ consul members
$ consul catalog nodes
```

List all service names registered to Consul.

```shell
$ consul catalog services
```

List all nodes associated with a specific registered service.  (Service names are listed by `consul catalog services`.)

```shell
$ consul catalog nodes -service=patroni
$ consul catalog nodes -service=db-replica
```

List all services registered by a specific node.  (Node names are listed by `consul catalog nodes`.)

```shell
$ consul catalog services -node=patroni-01-db-gprd
```

Put the local Consul agent (or a specific service it provides) into maintenance mode.  This is comparable to failing a health check for the node or service.

**Warning:** This state *persists* across agent restarts.  If maint mode is enabled, it must later be manually disabled.

```shell
$ consul maint -help
$ consul maint
$ consul maint -enable -reason 'Optional comment explaining why this node is being taken down'
$ consul maint -disable
```


### Consul REST API: Commands to inspect/explore Patroni's state stored in Consul's key-value (KV) store

Consul queries and operations can mostly be done via either the `consul` CLI tool or the consul agent's HTTP REST interface (TCP port 8500).
All of these Consul queries can be run from *any* host running a Consul agent in the environment you want to inspect (e.g. `gprd`, `gstg`, etc.).
It does not have to be a Patroni host, because all Consul agents participating in the same gossip membership list can also make RPC calls to the Consul servers.

Patroni uses the HTTP REST interface to interact with Consul agent.  To see these calls, run a packet capture of TCP port 8500 on the loopback interface.

Who is the current Patroni leader for the Patroni cluster named "pg-ha-cluster"?

**Note:** The response's `Session` key is deleted if the cluster lock is voluntarily released.  It acts as a mutex, indicating the session id of the Consul agent running on the current Patroni leader.

```shell
$ curl -s http://127.0.0.1:8500/v1/kv/service/pg-ha-cluster/leader | jq .
[
  {
    "LockIndex": 1,
    "Key": "service/pg-ha-cluster/leader",
    "Flags": 0,
    "Value": "cGF0cm9uaS0xMS1kYi1ncHJkLmMuZ2l0bGFiLXByb2R1Y3Rpb24uaW50ZXJuYWw=",
    "Session": "ee43c2cf-5b93-08b7-6900-1cf55c9e83b3",
    "CreateIndex": 34165794,
    "ModifyIndex": 34165794
  }
]
```

Show all the state data stored in Consul for this Patroni cluster.

**Note:** This is the same REST call that's run periodically by Patroni's `get_cluster` method.  The `Value` field is always base-64 encoded.  The decoded values are typically either JSON or a plain strings.

```shell
$ curl -s http://127.0.0.1:8500/v1/kv/service/pg-ha-cluster/?recurse=1 | jq .
```

List just the `Key` field of the Patroni cluster's Consul KV keys.

```shell
$ curl -s http://127.0.0.1:8500/v1/kv/service/pg-ha-cluster/?recurse=1 | jq -S '.[].Key'
```

Extract and decode the value of one of the above records.

```shell
$ curl -s http://127.0.0.1:8500/v1/kv/service/pg-ha-cluster/leader | jq -r '.[].Value' | base64 -d ; echo
```

Or use the `consul` CLI tool, and let it do the base-64 decoding for you.

```shell
$ consul kv get -detailed service/pg-ha-cluster/leader
```

Does this host's Consul agent have a Consul session?  If so, show its full details.

**Notes:**
* This shows the complete definition of a "consul session".
* Each Patroni agent has its own session.
* A consul agent can use its session `ID` as an advisory lock (mutex) on any consul KV record.  A session can claim exclusive ownership of that record by setting the record's `Session` attribute with its own `ID` value.  When the session is invalidated/expired, the lock is automatically released.
* This locking mechanism is how Patroni uses Consul to ensure that only one node is the Patroni leader (represented by the consul KV record "service/[cluster_name]/leader").

```shell
$ curl -s http://127.0.0.1:8500/v1/session/node/$( hostname -s ) | jq .
[
  {
    "ID": "0e9e66a5-d17a-3543-e389-209c90731209",
    "Name": "pg-ha-cluster-patroni-09-db-gprd.c.gitlab-production.internal",
    "Node": "patroni-09-db-gprd",
    "Checks": [
      "serfHealth"
    ],
    "LockDelay": 1000000,
    "Behavior": "delete",
    "TTL": "15.0s",
    "CreateIndex": 32308118,
    "ModifyIndex": 32308118
  }
]
```

List the consul session id for each Patroni agent in this Patroni cluster (`pg-ha-cluster`).

**Notes:**
* Failing the health check or expiring the TTL invalidates the session.  If that happens to the Patroni leader, it loses the cluster-lock, causing a failover.
* The TTL reported here is always half the value specified in the Patroni config, because Patroni divides that configured value by 2 before setting it in Consul.

```shell
$ curl -s http://127.0.0.1:8500/v1/session/list | jq -c '.[] | { ID, Name, TTL, Checks }' | grep 'pg-ha-cluster' | sort
```

Show which of the above session ids holds the lock as the Patroni leader.

Again, the existence of the `Session` field on this Consul record acts as the mutex.  If the session is invalidated (expires, fails a health check, or is deleted), then the `service/pg-ha-cluster/leader` is unlocked -- meaning no Patroni node holds the Patroni "cluster lock", causing Patroni to start its leader election process.

```
$ curl -s http://127.0.0.1:8500/v1/kv/service/pg-ha-cluster/leader | jq -r '.[].Value' | base64 -d ; echo

Or

$ consul kv get service/pg-ha-cluster/leader
```


### Internal Loadbalancer (ILB)

Unlike other components, the ILB is not a service/process/instance.  It is just a set of network routing rules, with no inline host or device acting as a proxy.  It is purely configuration in the network control plane.

A [Google Internal TCP/UDP Load Balancer](//cloud.google.com/load-balancing/docs/internal/) consists of the following components:
 - Forwarding rule, which owns the IP address of the load balancer (shared by all backends for routing purposes)
 - Backend Service, which contains instance-groups and/or instances (i.e. pool members)
 - Health check, for probing each backend instance

Here are `gcloud` commands for inspecting the above components of the ILB.
Navigating the [GCP Console web UI](https://console.cloud.google.com/net-services/loadbalancing/loadBalancers/list) is also intuitive.

Find and show the internal loadbalancer's forwarding rule.

```shell
$ gcloud --project='gitlab-production' compute forwarding-rules list | egrep 'NAME|pgbouncer'
$ gcloud --project='gitlab-production' compute forwarding-rules describe --region=us-east1 gprd-gcp-tcp-lb-internal-pgbouncer
```

Find and show the internal loadbalancer's target backend service.

```shell
$ gcloud --project='gitlab-production' compute backend-services list --filter="name~'pgbouncer'"
$ gcloud --project='gitlab-production' compute backend-services describe gprd-pgbouncer-regional --region='us-east1'
```

Find and show the internal loadbalancer's health check.

```shell
$ gcloud --project='gitlab-production' compute health-checks list | egrep 'NAME|pgbouncer'
$ gcloud --project='gitlab-production' compute health-checks describe gprd-pgbouncer-http
```

Show the latest results of health-checks against each of the backend-service's backends (i.e. the zone-specific instance-groups).

```shell
$ gcloud --project='gitlab-production' compute backend-services get-health gprd-pgbouncer-regional --region='us-east1'
```

Show that backend service's instance groups.

```shell
$ gcloud --project='gitlab-production' compute instance-groups list | egrep 'NAME|pgbouncer'
```

Describe those instance-groups.

```shell
$ ( for ZONE in us-east1-{b,c,d} ; do INSTANCE_GROUP="gprd-pgbouncer-${ZONE}" ; echo -e "\nInstance-group: ${INSTANCE_GROUP}" ; gcloud --project='gitlab-production' compute instance-groups describe "${INSTANCE_GROUP}" --zone="${ZONE}" ; done )
```

List the instances in those instance-groups.

```shell
$ ( for ZONE in us-east1-{b,c,d} ; do INSTANCE_GROUP="gprd-pgbouncer-${ZONE}" ; echo -e "\nInstance-group: ${INSTANCE_GROUP}" ; gcloud --project='gitlab-production' compute instance-groups list-instances "${INSTANCE_GROUP}" --zone="${ZONE}" ; done )
```

## Background details

### Purpose of each service

* Patroni provides cluster management for Postgres, automating failover of the primary db and reconfiguring replica dbs to follow the new primary db's transaction stream.
* Consul provides shared state and lock management to Patroni.  It also provides DNS-based service discovery, so database clients can learn when Patroni nodes fail or change roles.
* PgBouncer provides connection pooling for Postgres.  We have two separate styles of use for PgBouncer:
    * Access to the primary db transits a dedicated pool of PgBouncer hosts, which discover the current Patroni leader (i.e. the primary db) by querying Consul's DNS record `master.patroni.service.consul`.  In turn, database clients access that pool of PgBouncer hosts through a single IP address that is load balanced among the pool members by a Google Internal TCP Loadbalancer.  That load balanced IP address is published as the DNS A record `pgbouncer.int.gprd.gitlab.net`.
    * Access to each of the replica dbs transits either of 2 PgBouncer instances running locally on each Patroni host.  Database clients discover the list of available replica db PgBouncer instances by querying Consul's DNS `SRV` records for `db-replica.service.consul`.  For historical reasons (prior to running multiple PgBouncers per replica db), Consul also publishes DNS `A` records for `replica.patroni.service.consul` pointing to the 1st PgBouncer instance (the one bound to port 6432).

### Normal healthy interactions between these services

* Patroni uses Consul mainly as a lock manager and as a key-value datastore to hold Patroni cluster metadata.
    * Each Patroni agent must regularly:
        * Fetch the Patroni cluster's state from Consul.
        * Publish its own local node state to Consul.
        * Renew its Consul session lock.
    * If the Patroni leader fails to renew its session lock before the lock's TTL expires, the other Patroni nodes will elect a new leader and trigger a Patroni failover.
* Patroni agent makes REST calls to the local Consul agent.
  * To build a response, the Consul agent makes RPC calls to a Consul server, which is where state data is stored.  Consul agents do not locally cache KV data.
* Our Consul topology has 5 Consul servers and several hundred Consul agents.
    * **Consul servers:**
      * The Consul servers each store state locally, but only 1 (the Consul leader) accepts write requests.  Typically also only the Consul leader accepts read requests.
      * The non-leader Consul servers exist for redundancy and durability, as each Consul server stores a local copy of the event log.
      * Consul's CAP bias is to prefer consistency over availability, but with 5 servers, Consul can lose 2 and remain available.
      * Unreliable network connectivity can trigger a Consul leader election, which causes Consul to be unavailable until connectivity recovers to the point that a quorum is able to elect a new leader.  Such a Consul outage can in turn potentially cause Patroni to demote its leader and wait for Consul to become available so Patroni can elect a new leader.
    * **Consul agents:**
      * Every Consul agent participates in a gossip protocol (Serf) that natively provides a distributed node failure detection mechanism.
      * Whenever one Consul agent probes another and fails to elicit a prompt response, the probing node announces via gossip that it suspects the buddy it just probed may be down.  That gossip message quickly propagates to all other Consul agents.
      * Every agent locally logs this event, so we could look on any other host running Consul agent to see roughly when the event occurred.
      * This has proven to be a reliable detector for intermittent partial network outages in GCP's infrastructure.
* We also use Consul to publish via DNS which Patroni node is the leader (i.e. the primary db) and which are healthy replica dbs.
  * Database clients (e.g. Rails app instances) periodically query their host's local Consul agent via DNS to discover the list of available databases.  This list actually refers to PgBouncer instances, which proxy to Postgres itself.
  * If Consul's list of available dbs changes, our Rails app updates its internal database connection pool accordingly.


## Details of how Patroni uses Consul


### What is Patroni's purpose?

Patroni's job is to provide high availability for Postgres by automatically detecting node failure, promoting a replica to become the new writable primary, and coordinating the switchover for all other replicas to start following transactions from the new primary once they reach the point of divergence between the old and new primary's timelines.


### What is Consul's purpose?

Consul has 2 primary jobs:
* Store Patroni's state data in a highly-available distributed datastore.
* Advertise via DNS to database clients how to connect to a primary or replica database.


### How and why does Patroni interact with Consul as a datastore?

To accomplish its job, Patroni needs to maintain a strongly consistent and highly available representation of the state of all the Patroni cluster's Postgres instances.  It delegates the durable storage of that state data to an external storage service -- what it calls its Distributed Configuration Store (DCS).  Patroni supports several options for this DCS (Consul, Zookeeper, Etcd, and others); in our case, we chose to use Consul.

Patroni stores several kinds of data in its DCS (Consul), such as:
* Who is the current cluster leader? (consul key `service/pg-ha-cluster/leader`)
* Patroni config settings from the `dcs` stanza of patroni.yml. (consul key `service/pg-ha-cluster/config`)
* Each Patroni node periodically self-describes its status (xlog_location, timeline, role, etc.). (consul keys `service/pg-ha-cluster/members/[hostname]`)
* Other ancillary data, including a history of past failover events, metadata about an in-progress failover, whether or not failover is currently paused, etc.

*Warning:* If you need to manually `PAUSE` Patroni (i.e. prevent failover even if the primary starts failing health checks), a Chef run an *any* Patroni node will revert that pause.  Chef tells the Patroni agent to force the `dcs` settings in patroni.yml to overwrite any conflicting settings stored in Consul, and that scope unfortunately includes the consul key used for pausing failovers.  So to pause Patroni (e.g. for maintenance), we must first stop Chef on *all* Patroni hosts.

The Consul agent does not locally cache any of the above data.  Every time the Patroni agent asks the local Consul agent to read or write this data, the Consul agent must synchronously make RPC calls to a Consul server.  The Patroni agent's REST call to the Consul agent can timeout or fail if Consul agent's RPC call to Consul server stalls or fails.  (This has proven to be a common failure mode on GCP due to transient network connectivity loss.)


### What is the difference between the Patroni leader and the Consul leader?

The Patroni leader is the Patroni agent corresponding to the writable Postgres database (a.k.a. the primary Postgres db).  All other Patroni nodes correspond to read-only replica Postgres databases that asynchronously replay transaction logs received from the primary Postgres database.

The Consul leader is whichever one of the Consul servers is currently accepting writes.  Consul has its own internal leader-election process, independent of Patroni.


### Why use one database (Consul) to manage another database (Postgres)?

Patroni uses Consul to provide high availability to Postgres through automated failover.

Postgres and Consul are both databases, but they have different strengths and weaknesses.  Consul excels at storing a small amount of data, providing strong consistency guarantees while tolerating the loss of potentially multiple replicas.  But Consul is not designed to handle a high write rate, and it provides just basic key-value storage.  In contrast, Postgres is a much more featureful relational database and supports many concurrent writers.  While Postgres natively provides replication, it does not natively provide an automated failover mechanism.

For Patroni to provide high availability (automated failover) to Postgres, it needs all Patroni agents to have a consistent view of the Patroni cluster state (i.e. who is the current leader, how stale is each replica, etc.).  Patroni stores that state in its DCS (which for us is Consul), with the expectation that writes are durable and reads are strongly consistent.


### How does Consul balance consistency versus availability?

Consul prefers consistency over availability.  When failure conditions such as node loss or network partitions force Consul to choose between consistency and availability, Consul prefers to stop accepting writes and reads until a quorum of Consul server nodes is again reached.  This avoids split-brain.  To reduce the likelihood of losing quorum, Consul supports a peer group of up to 11 servers, but most production deployments use 3 or 5 (which tolerates the loss of 1 or 2 nodes respectively).

As is typical, in production we run 5 hosts as Consul servers to act as the datastore, and we run a Consul agent on every other host that need to read or write data stored on the Consul servers.

The Consul servers participate in a [strongly consistent consensus protocol (RAFT)](https://www.consul.io/docs/internals/consensus.html) for leader election.  Only the current leader is allowed to accept writes, so that all writes are serializable.  These logged writes are replicated to the other Consul servers; at least a majority (quorum) of Consul servers must receive the new log entry for the write to be considered successful (i.e. guaranteed to be present if a new leader is elected).  If the current leader fails, Consul will stop accepting new writes until the surviving quorum of peers elect a new leader (which may take several seconds).  Typically read requests are also handled by the Consul leader, again to provide strong consistency guarantees, but that is tunable.  If a non-leader consul server receives a read request, it will forward that call to the current Consul leader.

Only the Consul servers participate as peers in the strongly-consistent RAFT protocol.  But all Consul agents participate in a [weakly-consistent gossip protocol (SERF)](https://www.consul.io/docs/internals/gossip.html).  This supports automatic node discovery and provides distributed node failure detection.


### How do Patroni's calls to Consul let it decide when to failover?

Each Patroni agent (whether replica or primary) periodically interacts with Consul to:
* Fetch the most recently published status of its cluster peers.
* Publish its own current state metadata.
* Affirm its liveness by renewing its consul session (which quickly auto-expires without these renewals).

If Patroni fails one of these REST calls to Consul agent, the failed call can be retried for up to its configured `retry_timeout` deadline (currently 30 seconds).  For the Patroni leader (i.e. the Patroni agent whose Postgres instance is currently the writable primary db), if that retry deadline is reached, Patroni will initiate failover by voluntarily releasing the Patroni cluster lock.

Similarly, if the Patroni leader's loop takes long enough to complete that its consul session expires (TTL is currently effectively 45 seconds), then it involuntarily loses the cluster lock, which also initiates failover.


### What is Consul's `serfHealth` check, and how can it trigger a Patroni failover?

Another way for Patroni's leader to involuntarily lose its cluster lock is if Consul's `serfHealth` health check fails for that host's Consul agent.

[Consul uses Serf as its gossip protocol](https://www.consul.io/docs/internals/gossip.html).  In addition to being a medium for asynchronous eventually-consistent information sharing, Serf also provides Consul's mechanism for node failure detection.  Every host running a Consul agent participates in Serf gossip traffic, including its liveness probe: `serfHealth` ([also called `SerfCheck`](https://github.com/hashicorp/consul/blob/v1.5.1/agent/structs/catalog.go#L7)).  Each Consul agent intermittently tries to connect to a random subset of other agents, and if that attempt fails, it announces that target as being suspected of being down.  The suspected-down agent has a limit window of time to actively refute that suspicion.  Meanwhile, other agents will "dogpile" on health-checking the suspected-down agent, and if they concur that the agent is unresponsive, the window for refutation shortens (to reduce time to detect a legitimate failure).  After the refutation window expires, the Consul server can mark that Consul agent as failed.  When the problem is resolved (e.g. agent restarted, network connectivity restored), the failed Consul agent automatically rejoins by contacting the Consul server.

If a Patroni node's Consul agent is marked by its peers as failing that `serfHealth` check, then this immediately invalidates the Patroni agent's consul session (which, as described above, acts as a mutex).  If that happens to the Patroni leader, it immediately loses the Patroni "cluster lock", triggering a Patroni failover.  In contrast, if `serfHealth` check fails for a non-leader Patroni node, it is merely excluded as a candidate for leader election until it establishes a new session (which typically happens seconds after network connectivity is restored).

In summary, any host's Consul agent can flag the Patroni leader's Consul agent as potentially down, and if it does not promptly refute that claim, Patroni will initiate a failover -- all because Consul's `serfHealth` check is part of Patroni's contract for maintaining the validity of its consul session.

Because GCP network connectivity has proven to be intermittently unreliable, we are considering reconfiguring Patroni to ignore the `serfCheck`, so that its consul sessions would not be invalidated due to any one random VM in the environment having packet loss.  Pros and cons are described in [Issue 8050](https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/8050).


### How does `serfHealth` work?

**In brief:** A Consul agent first sends a UDP message probe.  If it gets no response, it asks a few other nodes to try the same UDP message while it concurrently tries one via TCP.  If those attempts all fail, it broadcasts via gossip a suspicion that the target node is dead.  If the target node does not explicitly refute that suspicion within the time limit, it is marked as failed by Consul server.  For more details, continue reading.

The following notes are from a source code review of [Consul 1.5.1](https://github.com/hashicorp/consul/tree/v1.5.1), which includes a fork of the [Serf library](https://github.com/hashicorp/consul/tree/v1.5.1/vendor/github.com/hashicorp/serf/serf).

For reference, the configuration options and their defaults are defined (and well-annotated) here:
* [Serf config.go](https://github.com/hashicorp/consul/blob/v1.5.1/vendor/github.com/hashicorp/serf/serf/config.go), with [default settings at the end](https://github.com/hashicorp/consul/blob/v1.5.1/vendor/github.com/hashicorp/serf/serf/config.go#L254)
* [MemberList config.go](https://github.com/hashicorp/consul/blob/v1.5.1/vendor/github.com/hashicorp/memberlist/config.go), with default settings near the end for the [Serf LAN](https://github.com/hashicorp/consul/blob/v1.5.1/vendor/github.com/hashicorp/memberlist/config.go#L225) (within "datacenter") and [Serf WAN](https://github.com/hashicorp/consul/blob/v1.5.1/vendor/github.com/hashicorp/memberlist/config.go#L269) (cross-"datacenter") scopes of communication.  Most of the timeouts mentioned below are defined here.

The node failure detection behavior using Serf primatives is implemented by [the `probeNode` method of `Memberlist`](https://github.com/hashicorp/consul/blob/v1.5.1/vendor/github.com/hashicorp/memberlist/state.go#L245).  Here is a walk-through of that behavior:

* Deadline for a probe is dynamic but is at least `Memberlist.Config.ProbeInterval` (default: 1 second).
* If the target node's current state is `stateAlive` (healthy), then just send a `pingMsg` via Gossip (UDP).  Otherwise, append a `suspect` message to the pingMsg and send it.
* Wait for an acknowledgement response for up to `Memberlist.Config.ProbeTimeout` (default: 500 ms).
  * Exit successfully if ack received within `ProbeTimeout` deadline.  Else continue.
* Concurrently try 2 tactics:
  * Tactic 1: Request indirect UDP probes: Ask up to `Memberlist.Config.IndirectChecks` nodes (default: 3) to ping the target node on our behalf.
  * Tactic 2: Try "fallback" TCP ping: If the target node speaks protocol version 3 or higher and `DisableTcpPings=false` (default), then open a TCP connection, and send the same `pingMsg`.
    * Note: The `deadline` variable passed to TCP ping has roughly `ProbeInterval` minus `ProbeTimeout` time remaining (default: 1000 ms - 500 ms = 500 ms).  The `deadline` variable was set to `time.Now().Add(ProbeInterval)` at the [*start* of the `probeNode` method](https://github.com/hashicorp/consul/blob/v1.5.1/vendor/github.com/hashicorp/memberlist/state.go#L273), and by this point we have already spend roughly `ProbeTimeout` (default: 500 ms) of that budgetted deadline.
    * Note: This is probably not a practical concern for the time scales involved, but for completeness: Both the Indirect UDP Pings and the TCP Ping are run in goroutines, so they may not run immediately if the Golang runtime has too few threads free (e.g. on a host with very few CPUs).  The TCP probe's `deadline` is an absolute timestamp, so any delay in scheduling a goroutine consumes part of the patience of that health check.
* Check results: Wait for the UDP-based indirect acks or nacks to arrive or timeout.  Then check the result of the TCP ping.
  * If any indirect UDP Ping succeeds, exit successfully.  If they all fail (timeout or nack), then check results of the TCP Ping.
  * If TCP Ping succeeded, log warning and exit successfully.
  * Note: We warn if only TCP succeeds because if UDP is consistently blocked/failing, the node cannot hear most gossip and may pollute peers with its stale state via full-sync.
* If those fallback probes all failed, then:
  * Update self-awareness metrics.
  * Call [method `suspectNode`](https://github.com/hashicorp/consul/blob/v1.5.1/vendor/github.com/hashicorp/memberlist/state.go#L1045):
    * Broadcasts via gossip the identity (name and incarnation number) of the node that failed its health check, and starts the timer for the refutation window.
* Other nodes in the cluster receive this `suspect` message and also locally call `suspectNode`.
  * If the suspected node receives this gossip message, its local call to `suspectNode` [notices the message refers to itself, logs a warning, and broadcasts a refutation message](https://github.com/hashicorp/consul/blob/v1.5.1/vendor/github.com/hashicorp/memberlist/state.go#L1078).  If egress network traffic is working, its peers should see this broadcast and accept this refutation; otherwise, the countdown continues until the node is marked as failed.
  * The duration of the refutation window is [calculated here](https://github.com/hashicorp/consul/blob/v1.5.1/vendor/github.com/hashicorp/memberlist/state.go#L1110) using settings from [MemberList config.go](https://github.com/hashicorp/consul/blob/v1.5.1/vendor/github.com/hashicorp/memberlist/config.go#L225).


### What happens during a Patroni leader election?

Patroni's leader election protocol allows a period of time for all replicas to catch up on any transaction data from the old primary db that they had received but not yet applied.  During that period, each Patroni node frequently updates its state (e.g. xlog replay location), so its peers know who is the freshest.  At the end of the grace period, the freshest replica will be promoted to become the new primary.

Patroni then helps each replica switch to the new primary's timeline, so they have a consistent point of divergence from the old primary's timeline and can safely apply transaction logs from the new primary.  If a replica fails to switch timelines for any reason, it is shutdown and removed from the list of replica dbs available for handling read-only queries.  (However, in this case the new primary db still needs to be manually told to stop retaining transaction logs for that dead replica.)

Meanwhile, the dedicated PgBouncer instances frequently query Consul DNS for updates, so they quickly detect that Patroni has promoted a new Postgres instance to be the primary db.  PgBouncer discards any residual connections to the old primary db, opens connections to the new primary db, and starts mapping client queries to these new db connections.  Clients such as Rails instances remain connected to PgBouncer throughout this process.  Transactions that were in progress at the time the primary db failed (or was demoted) are aborted, and newer transactions fail until the new primary db is elected by Patroni and detected by PgBouncer.


### Define the relationship between Patroni settings `ttl`, `loop_wait`, and `retry_timeout`

The [Patroni documentation](https://patroni.readthedocs.io/en/release-1.6.0/SETTINGS.html#bootstrap-configuration) is vague about how these 3 settings are used and how to tune them:

> * `loop_wait`: the number of seconds the loop will sleep. Default value: 10
> * `ttl`: the TTL to acquire the leader lock. Think of it as the length of time before initiation of the automatic failover process. Default value: 30
> * `retry_timeout`: timeout for DCS and PostgreSQL operation retries. DCS or network issues shorter than this will not cause Patroni to demote the leader. Default value: 10

The following more detailed description is based on review of the [Patroni 1.6.0 source code](https://github.com/zalando/patroni/tree/v1.6.0), specifically focusing on the [generic DCS code](https://github.com/zalando/patroni/blob/v1.6.0/patroni/dcs/__init__.py) and the [Consul-specific code](https://github.com/zalando/patroni/blob/v1.6.0/patroni/dcs/consul.py).

* `loop_wait` (seconds): The minimum delay the Patroni agent waits between attempts to renew the TTL of its consul session.  The consul session of the Patroni leader is effectively the leader lock; if the leader's consul session expires, the `services/[cluster_name]/leader` record will be deleted by the Consul server, and surviving Patroni agents will initiate a leader election.
* `ttl` (seconds): Effectively the TTL of the leader lock.  Technically every Patroni agent has a consul session with this TTL.  If the leader's consul session expires, the leader lock is released (i.e. the Consul KV revord named `services/[cluster_name]/leader` is automatically deleted), which surviving Patroni agents detect, initiating leader election.  If a non-leader Patroni node's consul session expires, it cannot publish status updates or participate in leader elections until it creates a new consul session.  All Patroni agents try to renew the TTL on their consul sessions approximately every `loop_wait` seconds, but only the leader's session expiry can cause failover.
* `retry_timeout` (seconds): The cumulative max duration of all tries of any *single* operation (e.g. a single REST operation to Consul can be retried for up to `retry_timeout` seconds.)  A typical healthy Patroni loop makes 3-4 REST calls to Consul.  If more than one is affected by slowness, the TTL could expire before Patroni issues the REST call to renew it.  In the Consul-specific Patroni code, each of 3 attempts at a REST HTTP call to Consul agent gets 1/3 of this `retry_timeout` budget.  (The [Retry object's overall deadline](https://github.com/zalando/patroni/blob/v1.6.0/patroni/dcs/consul.py#L185) is `retry_timeout`, and it wraps the [HTTP client object whose `read_timeout` is set to 1/3 of that value](https://github.com/zalando/patroni/blob/v1.6.0/patroni/dcs/consul.py#L61).)  Only the last of 3 failed attempts is logged, which is why its log message shows the HTTP timeout as being 1/3 of this configured value.

When adjusting these 3 settings, for the timeouts to work properly:
* `ttl` must be at least `loop_wait` + `retry_timeout`.  Otherwise the leader lock will implicitly expire either between renewal attempts or before a stalled DCS operation reaches its `retry_timeout`.
* `ttl` being comfortably larger than this makes it tolerate multiple slow calls to Consul.
* The default settings are equivalent to: `ttl` = `loop_wait` + 2 * `retry_timeout`


### Why is Patroni's actual TTL half of its configured value?

Surprisingly, Patroni [silently halves the configured `ttl` setting](https://github.com/zalando/patroni/blob/v1.6.0/patroni/dcs/consul.py#L245), because it expects Consul to silently double it.

```python
    def set_ttl(self, ttl):
        if self._client.http.set_ttl(ttl/2.0):  # Consul multiplies the TTL by 2x
        ...
```

Example: The default `ttl` is 30 seconds, but the actual consul session's TTL is really set to 15 seconds:

```shell
$ consul kv get service/pg-ha-cluster/config | jq -c '. | { ttl }'
{"ttl":30}

$ curl -s http://127.0.0.1:8500/v1/session/node/$( hostname -s ) | jq -c '.[] | { TTL }'
{"TTL":"15.0s"}
```

This hard-coded behavior may be helpful in environments that prefer a very strict TTL, typically with very small value -- in other words, environments that prefer to failover spuriously rather than waiting a little longer to see if the triggering condition was ephemeral or a false alarm.  The [Consul documentation](https://www.consul.io/docs/internals/sessions.html#session-design) also describes its TTL support as following a lazy expiry policy, but it does not claim any divide-by-two logic.  Rather it states the session TTL is a lower bound (not an upper bound) for when the Consul server will actually delete/release an expired session:

> When creating a session, a TTL can be specified. If the TTL interval expires without being renewed, the session has expired and an invalidation is triggered. [...] The contract of a TTL is that it represents a *lower bound for invalidation*; that is, Consul will not expire the session before the TTL is reached, but it is allowed to delay the expiration past the TTL.

So we should be aware that whatever value we set in Patroni's DCS ttl config, **Consul is being told half of that value**.  Despite the heuristic testing done 2 years ago when that divide-by-two logic was added to the Patroni code, a strict interpretation of the Consul docs suggests the session *could be expired as early as half* the time we specify in the Patroni `ttl` config.


## Known failure modes

The following lists some selected illustrative failure patterns and what their symptoms look like.


### What specific network paths can trigger Patroni failover if they become lossy?

See: ["Concise summary of RCA" comment on issue "Why are patroni failovers occurring so often?"](https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/7790#note_215232905)


### Dedicated PgBouncer hosts can develop a very uneven distribution of client connections after maintenance or restart events

See: [Why do the PgBouncer hosts have a very uneven distribution of client connections?](https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/7440)

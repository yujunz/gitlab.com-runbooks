# Load Balancer Outage

We utilize Azure load balancers to deal with failover of our postgres database.
Occasionally there will be an outage of the load balancer that will cause disruption.
For more information on our load balanced Postgres setup, visit the [docs section of chef-repo](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/tree/postgres-docs/doc)

## Determine if the outage is the vendor or us

There are several ways to determine if the problem is us or the vendor.
Firstly, check the [status page](https://azure.microsoft.com/en-us/status/). It sometimes isn't updated but it is still best
to check there first.

If the status page shows no issues, check to see if the worker nodes can connect to the
load balancer. The command I used to determine this was:

```
bundle exec knife ssh -C 2 -a ipaddress 'role:gitlab-cluster-worker' 'echo exit | telnet 10.1.0.25 5432'
```

As an example, you should see something like the following for each host.

```
<IP Address>     Trying 10.1.0.25...
<IP Address>     Connected to 10.1.0.25.
<IP Address>     Escape character is '^]'.
<IP Address>     Connection closed by foreign host.
```

If you do NOT see this for a host or it instead times out, that host cannot reach the postgres
server.

If some of the workers CAN reach postgres but others CANNOT, this is likely a Microsoft issue. 
You will need to [contact Microsoft support](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/doc/azure.md#creating-a-ticket-for-pro-direct-support-in-azure)
as soon as possible. They should reply within the hour.

## Workaround for Postgres

In the event of an actual load balancer outage causing postgres connectivity issues, we can 
work around the issue by changing the workers to connect directly to the current primary database.

In chef-repo, run `bundle exec rake 'edit_role[gitlab-cluster-worker]'` and change the DB IP to 
the primary DB server's IP.

Then run chef-client on all the workers:

```
bundle exec knife ssh -a ipaddress 'role:gitlab-cluster-worker' 'sudo chef-client'
```

This will solve the immediate connectivity issue.

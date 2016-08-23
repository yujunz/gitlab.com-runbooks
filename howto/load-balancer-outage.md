# Load Balancer Outage

We utilize Azure load balancers to deal with failover of our postgres database.
Occasionally there will be an outage of the load balancer that will cause disruption.

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
You will need to [contact Microsoft support](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/doc/azure.md#creating-a-ticket-for-pro-direct-support-in-azure)
as soon as possible. They should reply within the hour.

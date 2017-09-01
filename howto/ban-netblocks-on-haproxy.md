# Blocking individual IPs and Net Blocks on HA Proxy

## First and foremost

* *Don't Panic*
* Be very careful when manipulating the ip routing tables of machines. Check, and double check your work.

## Background

From time to time it may become necessary to block IP addresses or networks of IP addresses from accessing GitLab.
We do this by routing the requesting traffic into a 'blackhole' on the HA Proxy nodes.

### Important Note

A VPN Connection is needed to perform these actions! 

## How do I

### See what IP addresses are currently in the blackhole

On your workstation with a properly configured GitLab chef client, perform the following:

```
thor$ knife ssh -p 2222 -a ipaddress -C 2 'roles:gitlab-base-lb-fe' 'sudo ip route show| grep blackhole'
```

This will produce a listing of all of the blackhole IP addresses listed once per HA-Proxy node.

For a more concise listing you can run a command that massages the data:

```
thor$ knife ssh -p 2222 -a ipaddress -C 2 'roles:gitlab-base-lb-fe' 'sudo ip route show| grep blackhole' | tr -s ' ' | cut -d ' ' -f3 | sort -n | uniq -c 
```

This will produce a count and listing of all the IP addresses in the blackhole state on all of the HA Proxies.  The count should equal the number of HA Proxies in production.

### Add a netblock to the blackhole

Just like Santa Clause, you want to check your list twice before you sort the naughties into the blackhole.

```
thor$ knife ssh -p 2222 -a ipaddress -C 2 'roles:gitlab-base-lb-fe' 'sudo ip route add blackhole 192.168.1.0/24'
```

### Remove a netblock from the blackhole

More often than not, the source for the block is a transient to the network that it originates from and should be removed after the incident is over.

```
thor$ knife ssh -p 2222 -a ipaddress -C 2 'roles:gitlab-base-lb-fe' 'sudo ip route del blackhole 192.168.1.0/24'
```

## CLEAN UP

It is important to note that blackhole entires ***DO NOT*** clean up after themselves, you must remove the entries
after the threat or issue has been mitigated / resolved.  When a network is blackholed the users are not able to reach
ANY of the GitLab infrastructure that depends upon the HA Proxies (almost all of it!). This makes it even more important
that you clean up after yourself.

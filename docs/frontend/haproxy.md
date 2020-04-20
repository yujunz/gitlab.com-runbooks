# HAProxy management at GitLab

## Overview

GitLab uses HAProxy for directing traffic to various fleets in our
infrastructure. HTTP(S) and git traffic. There are clusters of haproxy nodes
that are attached to GCP load balancers. These are split into the following
groups:

* `<env>-base-lb-pages`: HTTP/HTTPS traffic for `*.pages.io`. It is also where customers point custom DNS for pages.
    * frontends: `pages_http`, `pages_https`
    * backends: `pages_http`, `pages_https`
* `<env>-base-lb-fe`: HTTP/HTTPS, SSH for gitlab.com
    * frontends: `http`, `https`, `ssh`
    * backends: `api`, `https_git`, `websocket`, `web`, `canary_web`,
      `canary_api`, `canary_https_git`, `canary_registry`
* `<env>-base-lb-altssh`: TCP port 443 for altssh.gitlab.com
    * frontends: `altssh`
    * backends: `altssh`
* `<env>-base-lb-registry`: HTTP/HTTPS for registry.gitlab.com
    * frontends: `http', `https`
    * backends: `registry`

Explanation:
* Each `<env>-base-lb-*` above represents a Chef role since we use Chef to
configure our nodes. Browse to `chef-repo/roles` directory and you will see them.
* The references after the _frontends_ and _backends_ refer to _node_ concept in
HAProxy configuration.

```
     client request
            |
            V
      Route53 DNS
            |
            V
    GCP Load Balancer
            |
            V
    HAProxy Frontend
            |
            V
     backend choice
            |
            V
    HAproxy Backend

```

## Frontend and Backend configuration
* HAProxy frontends define how requests are forwarded to backends
* Backends configure a list of servers for load balancing
* The HAProxy configuration is defined in [gitlab-haproxy cookbook](https://gitlab.com/gitlab-cookbooks/gitlab-haproxy) and you can also find it in `/etc/haproxy/haproxy.cfg` on any of the haproxy nodes.
*
### Frontends
* `http`: port 80
    *  delivers a 301 to https
* `https`: port 443
    * sends to the `api` rate limited backend if the request matches `/api` (skips the rate limit if your ip is on a statically configured whitelist)
    * sends to the `https_git` backend if the request matches a regex that tries to determine if it looks like a git path
    * sends to the `registry` backend if the request is registry.gitlab.com
    * sends to the `websocket` backed if it looks like a websocket request
    * sends to the `canary_web` backend if it looks like a canary request (cookie and `canary.\*`)
    * If nothing else matches requests are sent to the `web` backend.
* `ssh`: port 22
    * sends to the `ssh` backend
* `api_rate_limit`: used for the https front-end (see above)
* `altssh`: port 443
    * sends to the `altssh` backend
* `pages_http`: port 80
    * sends to the `pages_http` backend
* `pages_https`: port 443
    * sends to the `pages_https` backend

### Backends

* `api`: all of the `api-xx` nodes
* `api_rate_limit`: proxy for the `api_rate_limit` front-end
* `https_git`: all of the `git-xx` nodes
* `web`: all of the `web-xx` nodes
* `registry`: all of the `registry-xx` nodes
* `ssh`: all of the `git-xx` nodes
* `websockets`: all of the `git-xx` nodes
* `altssh`: all of the `git-xx` nodes
* `pages_http`: all of the `web-pages-xx` nodes
* `pages_https`: all of the `web-pages-xx` nodes
* `canary_web`: all of the `web-cny-xx` nodes
* `canary_api`: all of the `api-cny-xx` nodes
* `canary_https_git`: all of the `git-cny-xx` nodes
* `canary_registry`: all of the `registry-cny-xx` nodes

## Load balancing

Currently the haproxy backend configuration is such that every pool of servers is round-robin with the exception of websockets, ssh and pages.
There is an open issue to discuss using sticky sessions for the web backend, see https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/5253.


## Server Weights

By default all servers attached to the backends have the same weight of `100`
with the exception of the canary servers which are also in the non-canary
backends with a weight of zero. It is possible to direct all traffic to canary
but the normal way we send traffic is through a static list of request paths for
internal projects. For more information see the
[canary release documentation](https://gitlab.com/gitlab-org/release/docs/blob/master/general/deploy/canary.md)


## Draining

The haproxy nodes need to be drained of traffic before restarts of the node or haproxy binary can be applied.

In order to simplify this, the haproxy deployment includes a drain and wait script. By default, it waits 10 minutes. It works by blocking the health checks from the upstream GCP load balancer. Note, that not all HTTP connections will be drained in 10 minutes. The HTTP clients can, and do, keep long-lived sessions open. So a small number of users will get disconnected when doing a drain. But it will cleanly clear out the majority of traffic.

This script is automatically called as part of the systemd unit start and stop process. This allows for easy draining and restarting of haproxy.

For example:

```console
$ sudo systemctl stop haproxy
```

NOTE: This stop command will wait 10 minutes before it completes.

To drain the node with a custom time, or drain without stopping haproxy:

```console # Drain, but wait 1 minute
$ sudo /usr/local/sbin/drain_haproxy.sh -w 60
```

Un-draining is executed as part of the haproxy systemd unit start process. It can also be done manually by calling the drain script again in un-drain mode.

```console
$ sudo /usr/local/sbin/drain_haproxy.sh -u
```

## Tooling

* There are helper scripts in [chef-repo](https://ops.gitlab.net/gitlab-cookbooks/chef-repo) to assist setting server statuses. In general, it is advised to always drain active connections from a server before rebooting.
* For controlling traffic to canary there are chatops commands, for more
  information see the
  [canary chatops documentation](https://gitlab.com/gitlab-org/release/docs/blob/master/general/deploy/canary.md#canary-chatops)

The following helper script can be used for setting the state of any server in
the backend:

### get-server-state

```
$ ./bin/get-server-state gstg
Fetching server state...
   2 altssh/git-01-sv-gstg: UP
   2 altssh/git-02-sv-gstg: UP
   3 api/api-01-sv-gstg: UP
   3 api/api-02-sv-gstg: UP
   3 api/api-cny-01-sv-gstg: UP
   3 canary_web/web-cny-01-sv-gstg: UP
   3 https_git/git-01-sv-gstg: UP
   3 https_git/git-02-sv-gstg: UP
   3 https_git/git-cny-01-sv-gstg: UP
   2 pages_http/web-01-sv-gstg: UP
   2 pages_http/web-02-sv-gstg: UP
   2 pages_https/web-01-sv-gstg: UP
   2 pages_https/web-02-sv-gstg: UP
   3 ssh/git-01-sv-gstg: UP
   3 ssh/git-02-sv-gstg: UP
   3 ssh/git-cny-01-sv-gstg: UP
   3 web/web-01-sv-gstg: UP
   3 web/web-02-sv-gstg: UP
   3 web/web-cny-01-sv-gstg: UP
   3 websockets/git-01-sv-gstg: UP
   3 websockets/git-02-sv-gstg: UP
   3 websockets/git-cny-01-sv-gstg: UP
```
* The first number refers to the number of load balancers reporting the server status
* The second field is the backend/server-name
* The last field is the current status which may be {UP,MAINT,DRAIN}


## set-server-state

The `set-server-state` script allows you change the server state so that it can
start draining connections or not take any if there is a situation where you do
not want _any_ traffic going to a server.

```
Sets server state on frontend lbs
./bin/set-server-state {gprd,gstg} <ready|drain|maint> [filter]

Examples:
   ./bin/set-server-state gstg drain git-10  # set git-10 to drain
   ./bin/set-server-state gstg ready git-10  # set git-10 to ready
```

Here is a full example of setting server git-01 in gstg to the `DRAIN` state:

```
$ ./bin/set-server-state gstg drain git-01
Fetching server state...
   2 altssh/git-01-sv-gstg : UP
   3 https_git/git-01-sv-gstg : UP
   3 ssh/git-01-sv-gstg : UP
   3 websockets/git-01-sv-gstg : UP
^^^^^ The states of the above servers will be changed to drain.
Press enter to continue.
Setting server state...
   2 updated altssh/git-01-sv-gstg
   3 updated https_git/git-01-sv-gstg
   3 updated ssh/git-01-sv-gstg
   3 updated websockets/git-01-sv-gstg
Fetching server state...
   2 altssh/git-01-sv-gstg : DRAIN
   3 https_git/git-01-sv-gstg : DRAIN
   3 ssh/git-01-sv-gstg : DRAIN
   3 websockets/git-01-sv-gstg : DRAIN
```

## bin/haproxy-server-roles

When servers or haproxy VMs are added to the fleet, the corresponding chef role must be
updated so that:

1. HAProxy VMs have the peer list
2. Servers are added to the proper backend

This is semi-automated by running a helper script which will automatically
generate role files:

```
bin/haproxy-server-roles -u <chef user> -k <path/to/chef/key>
```

This script is also run in CI and will fail the job if there is a missing server
that needs to be added.

### Admin console for haproxy (single node)
haproxy has a built-in web admin console; this is not terribly useful for managing a fleet of haproxy nodes, but if just one is misbehaving then it might be handy.  To access it, ssh port forward to port 7331, e.g.:

`ssh -L 7331:localhost:7331 fe-01-lb-gstg.c.gitlab-staging-1.internal`

then access http://localhost:7331/ in  your browser.

The username is admin, the password is most easily obtained from haproxy.cfg on the server itself (look for 'stats auth' section), but can also be obtained by looking for the admin_password value in gkms vault, e.g.

`gkms-vault-show frontend-loadbalancer gstg`

# HAPrpoxy Alert Troubleshooting

## Reason
* Errors are being reported by HAProxy, this could be a spike in 5xx errors,
  server connection errors, or backends reporting unhealthy.

## Prechecks
* Examine the health of all backends and the HAProxy dashboard
    * HAProxy - https://dashboards.gitlab.net/d/ZOOh_aNik/haproxy
    * HAProxy Backend Status - https://dashboards.gitlab.net/d/7Zq1euZmz/haproxy-status?orgId=1
* Is the alert specific to canary servers or the canary backend? Check canaries
  to ensure they are reporting OK. If this is the cause you should immediately change the weight of canary traffic.
    * Canary dashboard - https://dashboards.gitlab.net/d/llfd4b2ik/canary
    * To disable canary traffic see the [canary chatops documentation](https://gitlab.com/gitlab-org/release/docs/blob/master/general/deploy/canary.md#canary-chatops)

## Resolution
* If there is a single backend server alerting, check to see if the node is healthy on
  the host status dashboard. It is possible in some cases, most notably the git
  server where it is possible to reject connections even though the server is
  reporting healthy.
    * on the server see the health of the service `gitlab-ctl status`
    * for git servers check the status of ssh `service sshd_git status`
* HAProxy logs are not currently being sent to ELK because of capacity issues.
  These logs can be viewed in stackdriver. Production logs can be viewed using this [direct link](https://console.cloud.google.com/logs/viewer?project=gitlab-production&authuser=1&minLogLevel=0&expandAll=false&timestamp=2018-10-08T07:43:05.667000000Z&customFacets=&limitCustomFacetWidth=true&dateRangeStart=2018-10-08T06:43:05.918Z&dateRangeEnd=2018-10-08T07:43:05.918Z&interval=PT1H&resource=gce_instance&scrollTimestamp=2018-10-08T07:42:43.008000000Z&logName=projects%2Fgitlab-production%2Flogs%2Fhaproxy)
* If the errors are from web-pages backends, consider possible intentional abuse or accidental DoS from specific IPs or for specific domains in [Pages](https://us-central1-gitlab-infra-automation-stg.cloudfunctions.net/ui/services/pages)
  * Client IPs can be identified by volume from the current haproxy logs on the haproxy nodes with `sudo grep -v check_http /var/log/haproxy.log | awk '{print $6}' | cut -d: -f1|sort|uniq -c |sort -n|tail`.  Identifying problematic levels is not set in stone; hopefully if there is one or two (or a subnet), they will stand out.  Consider removing the 'tail' or making it 'tail -100' etc, to get more context.
    * To block: In https://gitlab.com/gitlab-com/security-tools/front-end-security/ edit deny-403-ips.lst.  commit, push, MR, ensure it has pull mirrored to ops.gitlab.net, then run chef on the pages haproxy nodes to deploy.  This will block that IP across *all* frontend (pages, web, api etc), so be sure you want to do this.
  * Problem sites/projects/domains can be identified with the `Gitlab-Pages activity` dashboard on kibana - https://log.gprd.gitlab.net/app/kibana#/dashboard/AW6GlNKPqthdGjPJ2HqH
    * To block: In https://gitlab.com/gitlab-com/security-tools/front-end-security/ edit deny-403-ips.lst.  commit, push, MR, ensure it has pull mirrored to ops.gitlab.net, then run chef on the pages haproxy nodes to deploy.  This will block only the named domain (exact match) in pages, preventing the request ever making it to the web-pages servers.  This is very low-risk

## Extraneous processes

HAProxy forks on reload and old processes will continue to service requests, for
long-lived ssh connections we use the `hard-stop-after` [configuration parameter](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/6156b09464c18bc5b584f5bf5e363fd50ded4af7/roles/gprd-base-lb-fe.json#L6-10)
to prevent processes from lingering more than 5 minutes.

In https://gitlab.com/gitlab-com/gl-infra/delivery/issues/588 we have observed that processes remain for longer than this interval, this may require manual intervention:

* Display the process tree for haproxy, for example here it shows two processes where we expect one:

```
# pstree -pals $(pgrep -u root -f /usr/sbin/haproxy)
systemd,1 --system --deserialize 36
  └─haproxy,28214 -Ws -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -sf 1827
      ├─haproxy,1827 -Ws -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -sf 1639
      └─haproxy,2002 -Ws -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -sf
```

* Show the elapsed time of the haproxy processes:

```
# for p in $(pgrep -u haproxy -f haproxy); do ps -o user,pid,etimes,command $p; done
USER       PID ELAPSED COMMAND
haproxy   1827   99999 /usr/sbin/haproxy -Ws -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -sf 1639
USER       PID ELAPSED COMMAND
haproxy   2002      20 /usr/sbin/haproxy -Ws -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -sf 1827

```

* Kill the process with the longer elapsed time:

```
# kill -TERM 1827
```

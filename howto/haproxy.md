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


## Tooling

* There are helper scripts in [chef-repo](https://ops.gitlab.net/gitlab-cookbooks/chef-repo) to assist setting server statuses. In general, it is advised to always drain active connections from a server before rebooting.
* For controling traffic to canary there are chatops commands, for more
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
   2 registry/registry-01-sv-gstg: UP
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

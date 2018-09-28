# Canary in GCP production and staging

## Overview
The canary fleet is a subset of fleet within the production and staging
environment that can be deployed to independently of the main environment.

When querying in prometheus, metrics for canary are labeled as:

`stage=cny`

Non-canary boxes are labeled as:

`stage=main`

### HOW TO STOP ALL PRODUCTION TRAFFIC TO CANARY

Canary is the first stage that receives production traffic, if you want to stop
all production traffic from reaching canary execute the following command in the
[chef-repo bin dir](https://dev.gitlab.org/cookbooks/chef-repo/tree/master/bin):

```
./bin/set-canary-weights gprd 0
```

### Dasbhoards

### Utilities

There are two scripts that help to manage canary traffic and can be used to
either increase the amount of production traffic that goes to the canary or
reduce it. These scripts are located in the [chef-repo bin
dir](https://dev.gitlab.org/cookbooks/chef-repo/tree/master/bin).

### Getting the server weights of the fleet

When the canary was introduced in GCP we also added server weights so that we
can direct some production traffic to the canary. By default, the weight of all
canary nodes are set to zero, so no traffic will go to them unless the canary
cookie is set.

To see all server weights, use the `./bin/get-weights` script.

(example for gstg)

```
$ ./bin/get-weights gstg
   3 api/api-01-sv-gstg : 100 (initial 100)
   3 api/api-cny-01-sv-gstg : 0 (initial 0)
   3 canary_web/web-cny-01-sv-gstg : 1 (initial 1)
   3 https_git/git-01-sv-gstg : 100 (initial 100)
   3 https_git/git-cny-01-sv-gstg : 100 (initial 0)
   3 ssh/git-01-sv-gstg : 100 (initial 100)
   3 ssh/git-cny-01-sv-gstg : 100 (initial 0)
   3 web/web-01-sv-gstg : 100 (initial 100)
   3 web/web-cny-01-sv-gstg : 100 (initial 0)
   3 websockets/git-01-sv-gstg : 100 (initial 100)
   3 websockets/git-cny-01-sv-gstg : 100 (initial 0)
```

* The first number `3` refers to the number of backends that queried or set, this corresponds to
  the number of haproxy servers that have the canary server.
* `: <num>` refers to the current weight
* `(initial <num>)` refers to the initial weight value, for canaries this will always be zero

To see the weighting of just the canary servers you can add a filter:

```
$ ./bin/get-weights gstg cny
   3 api/api-cny-01-sv-gstg : 0 (initial 0)
   3 canary_web/web-cny-01-sv-gstg : 1 (initial 1)
   3 https_git/git-cny-01-sv-gstg : 100 (initial 0)
   3 ssh/git-cny-01-sv-gstg : 100 (initial 0)
   3 web/web-cny-01-sv-gstg : 100 (initial 0)
   3 websockets/git-cny-01-sv-gstg : 100 (initial 0)

```

### Setting server weights to direct traffic to canary

By default, all servers have a weight of 100. To give the canary equal traffic as
the rest of the fleet use the `set-canary-weights` script as follows:

(example for gstg)

```
$ ./bin/set-canary-weights gstg 100
   3 api/api-cny-01-sv-gstg : 0 (initial 0)
   3 https_git/git-cny-01-sv-gstg : 0 (initial 0)
   3 ssh/git-cny-01-sv-gstg : 0 (initial 0)
   3 web/web-cny-01-sv-gstg : 0 (initial 0)
   3 websockets/git-cny-01-sv-gstg : 0 (initial 0)
^^^^^ The weights of the above servers will be changed to 100.
Press enter to continue.
continuing...
   3 updated api/api-cny-01-sv-gstg
   3 updated https_git/git-cny-01-sv-gstg
   3 updated ssh/git-cny-01-sv-gstg
   3 updated web/web-cny-01-sv-gstg
   3 updated websockets/git-cny-01-sv-gstg

```

Optionally you can apply a filter to only set the weight for a single backend.
The following command will ensure that no api traffic is sent to the canary api
server:

```
$ ./bin/set-canary-weights gstg 0 api
   3 api/api-cny-01-sv-gstg : 100 (initial 0)
^^^^^ The weights of the above servers will be changed to 0.
Press enter to continue.
continuing...
   3 updated api/api-cny-01-sv-gstg

```

### Monitoring

Because canary nodes are included in the existing gprd and gstg environments,
existing alerts and monitors will cover them. There is a dedicated canary
dashboard that gives a general overview of traffic and errors:

* https://dashboards.gitlab.net/d/llfd4b2ik/canary?orgId=1

And the [GitLab Triage](https://dashboards.gitlab.net/d/RZmbBr7mk/gitlab-triage) dashboard includes canary traffic in the workhorse graph.

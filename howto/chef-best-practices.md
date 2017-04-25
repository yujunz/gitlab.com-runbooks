# The GitLab way

The purpose of this page should be to document how we at GitLab use chef, write cookbooks and configure nodes. It is a work in progress, however the points made here should be agreed upon by those who work with chef on a daily basis.


## Nodes dos and donts
### **do**:
#### Node run_lists
Keep a node simple - single purpose driven role applied on a node. 
IE a front end web server should have a single role on it: 
```json
"run_list": [
  role[frontend-web-server]
]
``` 
rather than:
```json
"run_list": [
  "role[base]",
  "role[do-droplet]",
  "role[frontend]",
  "role[web-server]"
]
```
Similarly, avoid (manually) setting attributes on nodes directly.
A node should be an instance of a role, making it a repetable and generic entity, rather than a patchwork of multiple different purposes. Cleaning this up would make the transition to cattle one step closer.

### dont:
#### Mix attributes
See cookbooks bellow.

## Cookbooks

### Buy vs. Build 
Do we have to build a cookbook or is there a well maintained one we can use (e.g. via wrappers/lwrps) without having to build our own? This should be the first question to ask yourself and it merits a few hours of research to determine if a cookbook is already out there to satisfy our needs. 

Including these cookbooks can be done via different ways via so called wrapper cookbooks.
####Wrapper Pattern
The Chef Cookbook Wrapper Pattern is based upon a design convention where you customize an existing "library" cookbook by using:
##### Libraries
Cookbooks can gather common tasks into libraries to ensure that the code is DRY.
Example:
[Only execute on supported platforms](https://github.com/jtimberman/enforce_supported_platform-cookbook)
Simplifies [this](https://gitlab.com/gitlab-cookbooks/gitlab-nfs-cluster/commit/739040f16e901c66fa70ed6014768898f0b67f6a#16f5421f9f20b9e5d3af7fc7cdd6ff9b7de716cc_0_1) to [this](https://gitlab.com/gitlab-cookbooks/gitlab-nfs-cluster/commit/ebd432345d4356818ad4a85ac436b33c9f9c8d65#2aeda62be0e44bf1b010cc93e2e1ed1348a65b4c_4_4)

##### Custom Resources (aka LWRPs)
Cookbooks can use [custom resources](https://docs.chef.io/custom_resources.html) to abstract the access to groups of tasks (e.g. installing, configuring, starting...) 
Example:
[REDISIO cookbook with LWRPs](https://github.com/brianbianco/redisio#lwrp-examples)

The redisio cookbook offers all the necessary LWRPs to install and configure a redis instance, but does not actually do anything itself if the default recipe is not called. 

```
redisio_install "redis-installation" do
  version '2.6.9'
  download_url 'http://redis.googlecode.com/files/redis-2.6.9.tar.gz'
  safe_install false
  install_dir '/usr/local/'
end
```
By calling the LWRP we are agnostic to changes in the cookbook background, in the same way we access all chef resources. It does mean we need a wrapping recipe.

##### Attributes and includes
Cookbooks can rely on all configuration to be available via attributes on a node, allowing all configuration to be done via that route.
Example:
[REDISIO cookbook with attributes and includes](https://github.com/brianbianco/redisio#role-file-examples)
```
run_list *%w[
  recipe[redisio]
  recipe[redisio::enable]
]

default_attributes({
  'redisio' => {
    'servers' => [
      {'name' => 'master', 'port' => '6379', 'unixsocket' => '/tmp/redis.sock', 'unixsocketperm' => '755'},
    ]
  }
})
```
By setting attributes on e.g. the role, we can don't have to make any programmatic changes to a cookbook since the logic is still in the default redisio recipe.

It is important to note that a wrapper cookbook does not extend functionality, only configures and includes the library cookbook!



##### Abstract Pattern
This pattern utilizes the flexibility of chef by implementing resources in a general (abstract) cookbook, and then coding the provider with the concrete implementation in the derived cookbook.

Example
[Abstract cookbook](https://github.com/rightscale/rightscale_cookbooks/tree/master/cookbooks/db/)
vs.
[Concrete cookbook](https://github.com/rightscale/rightscale_cookbooks/tree/master/cookbooks/db_mysql)



### Declarative
Each chef run should **ALWAYS** describe the node in the same way.
Avoid [if statements](https://gitlab.com/gitlab-cookbooks/gitlab-nfs-cluster/commit/f772209475bdc4dac1a530f80666dda6c3e6ec93#16f5421f9f20b9e5d3af7fc7cdd6ff9b7de716cc_23_15) which would cause chef resources to appear and disappear. Instead, make use of [guards](https://docs.chef.io/resource_common.html#guards) to skip over resources such as [here](https://gitlab.com/gitlab-cookbooks/gitlab-nfs-cluster/commit/c78108caffcdfd2e37cf2ba59759fbb93f77db4a#16f5421f9f20b9e5d3af7fc7cdd6ff9b7de716cc_29_22). This ensures that we **DECLARE** what our infrastructure should look the same way every time chef-client runs.

### Cookbook Attributes
Attributes are your friends:

* all attributes attributed to a cookbook should be:
    - nested under a common, understandable hash e.g. 

*sshd settings*
```
node['openssh']['sshd']['port']
node['openssh']['sshd']['address_family']
```
vs. *unreadable settings*:
```
node['openssh_port']
node['address_family']
```
  - Kept in the respective cookbook. 
     Roles are the place where you can change settings, not in unrelated cookbooks. e.g. the haproxy cookbook is not the place for [openssh settings](https://gitlab.com/gitlab-cookbooks/gitlab-haproxy/commit/f8aaa5d3ec344fba38bd15948d04854317e9e3ce#20875b27e096b4a4356a90b6ae97d03a1dbf877a_35_32).

  - Come with sane defaults. This plays into the testability of  a cookbook. Never assume that attributes will be set elsewhere: set defaults of fail.
* Try to avoid setting attributes via cookbooks e.g. `node.default['openssh']['sshd']['port'] = 23` this becomes hard to follow, when you are searching for the cause of issues.
### Documentation
Unless you are writing an actual food related cookbook, bacon should **NOT** be part of your README.md 

A cookbook should not be considered **DONE** unless the following is documented:

*  Description - What does this cookbook do?
* Attributes - what are relevant and important attributes we expect, and what are their defaults?
* Recipes - what does each recipe do?
* LWRPs: 
    * name
    * Actions
    * Attributes
    * Example


### Tests
#### Chefspec
Chefspec has been mentioned quite a few times here, and its the fastest way to test cookbooks. Ensure that at *least*  there are chefspec tests for your cookbook. 

#### Kitchen
[Kitchen](http://kitchen.ci/docs/getting-started/) tests are integration tests, they converge your cookbook and run it on an actual (e.g. vbox) node. This opens the door for lots of different tests, the first and foremost: does my recipe actually run.
Furthermore you can write tests in essentially any test framework, e.g. [BATS](https://github.com/sstephenson/bats) or [serverspec](http://serverspec.org/).

# The GitLab way

The purpose of this page should be to document how we at GitLab use chef, write cookbooks and configure nodes. It is a work in progress, however the points made here should be agreed upon by those who work with chef on a daily basis.


## Nodes dos and donts
### **do**:
#### Node run_lists
Keep a node simple - single purpose driven role applied on a node. 
iE a front end web server should have a single role on it: 
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

## Cookbooks
### Declarative
Each chef run should **ALWAYS** describe the node in the same way.
Avoid [if statements](https://gitlab.com/gitlab-cookbooks/gitlab-nfs-cluster/commit/f772209475bdc4dac1a530f80666dda6c3e6ec93#16f5421f9f20b9e5d3af7fc7cdd6ff9b7de716cc_23_15) which would cause chef resources to appeare and disapeare. Instead, make use of [guards](https://docs.chef.io/resource_common.html#guards) to skip over resources such as [here](https://gitlab.com/gitlab-cookbooks/gitlab-nfs-cluster/commit/c78108caffcdfd2e37cf2ba59759fbb93f77db4a#16f5421f9f20b9e5d3af7fc7cdd6ff9b7de716cc_29_22). This ensures that we **DECLARE** what our infrastructure should look the same way everytime chef-client runs.

### Attributes
Attributes are your friends:
* 

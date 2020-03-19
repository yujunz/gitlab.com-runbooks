## Remove VM

### Checklist for removing VM from the Azure

1. Remove VM
1. Cleanup all the related resources for the allocated VM (disks, network interfaces, etc)
1. Delete VM from the chef serve

### Removing the VM from the chef server

1. Execute `knife node delete example.gitlap.com`, where is `example.gitlap.com` is the node name.
1. Delete corresponding files from the chef-repo. Usually it is `nodes/example.gitlap.com.json` and related roles.

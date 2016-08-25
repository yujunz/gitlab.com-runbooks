# CephFS Runguide

## CephFS Overview

CephFS is a distributed file system that is build on top of the Ceph block
storage system. CephFS operates by presenting a posix layer to client systems
that mount the storage.  This is accomplished by a native kernel driver extension
for the client (there is also a FUSE driver, but we do not use this).

### CephFS Server Roles

Ceph and CephFS have three main components:

1. Clients that mount the storage via Kernel or FUSE mounts.
2. Monitoring and meta-data servers that tell the clients where to access files.
3. Back-end storage servers that have large amounts of disk space attached.


## CephFS Implimentation

All 20 of the worker nodes mount `/var/opt/gitlab/git-data-ceph` from the CephFS
servers.  The CephFS farm has three monitoring and metadata servers
(ceph-mon1, ceph-mon2, and ceph-mon3) and 10 back-end data storage servers
(ceph-osd[1-10]).  In CephFS speak the back in servers are 'osd'
Object Storage Daemons while the front-end servers are labeled `mon` for
monitoring and also serve the MDS (Meta Data Service) function. The MDS function
is what keeps a catalog of where all the file objects are written across
the OSD targets.

## Common Tasks and Functions

### Checking the Health of the Service

From any of the monitor (ceph-mon) servers or osd servers (ceph-osd) issue the
following command to view the health:

`ceph health`

This will tell you the simple and immediate status of the cluster.  For a more
in depth look at the health of the cluster issue:

`ceph status`

For a detailed look at the status of every disk within the Ceph cluster issue
the following:

`ceph osd tree`

### Adding a Worker Client

Add the role `gitlab-ceph-client` to the worker node. This will install the cephfs
kernel drivers, add the secret keys for mounting our ceph cluster, and mount the
git-data-ceph volume up on the client and create an fstab entry.

## Growth and Expansion Tasks

### Adding an OSD Server

The Azure machine for the build must be of type `Standard_DS14` and located in
the ARM resource side of the `eastus2` data center.  It should belong to the
Resource Group `Ceph-Prod` and have two NICS associated with it.  The first NIC
should be in the `CephFrontEnd` subnet with the second NIC being in the `CephReplication`
subnet as well as the `NSG-CephReplication` Network Security Group.  The primary NIC
will have an IP address in the 10.42.1.0/24 network while the secondary NIC will have
an IP address in the 10.42.5.0/24 network. It is important to note that the 10.42.5.0/24
network is for Ceph replication only and is not reachable from the Azure "Classic"
infrastructure resources.  Each OSD server should also have attached to it 25 1TB
SSD disks.  24 of these disks will be user for data storage while one disk will
be used for Ceph Journaling (this disk is /dev/sdaa).

Once the node is built and communicating on the network, it is ready to be
added to the cluster.  This task is done as the 'ceph-deploy' user on ceph-mon1
with configuration and keys located in the `/home/ceph-deploy/ceph-cluster directory.

From within the ceph-cluster directory issue the following commands at the target
OSD that you wish to enroll:

`ceph-deploy install **new-osd-server`

This establishes the osd node as a member of the cephfs cluster and distributes
the keys needed to be an active member of the cluster for file and data transfer.

In order to add the disks to the CephFS cluster you need to prepare the disk:

`ceph-deploy disk prepare **new-osd-server:/dev/sda1**`

Once the disk is prepared you can add the disk to the CephFS Cluster

`ceph-deploy osd create **new-osd-server:/dev/sda1** /dev/sdaa`

### Rebalancing the Placement Groups

Ceph uses 'placement groups' to determine how data is written to the OSD drives
in the cluster.  The formula for determing what the 'pg_num' value should be is
as follows:

Total PGs = ( OSD Drives * 100 ) / Replication Factor

This number is then raised to the next highest power of 2.  Our current 'pg_num'
value is 8192. We arrive at this the following way:

240 * 100 / 3 = 8000, the next highest power of two available is 8192.  In order to
set and rebalance the OSD's and CephFS service perform the following command:

`ceph osd pool set git_data pg_num 8192`

Once this is done the data will begin to be writeen to the new space, but data
replication will not happen until you adjust the gpg_num assocaited withi the OSD
target.  To perform that action issue the following command:

`ceph osd pool set git_data gpg_num 8192`

The pg_num and gpg_num should always track with each other in lock-step.

### Adding Disks to an OSD Server

Don't - Each OSD server should be created with 24 1TB disk targets for storage, 
when that is approaching full spin up another OSD server with another 24 1TB disks.

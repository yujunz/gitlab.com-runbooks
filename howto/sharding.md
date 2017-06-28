# Managing GitLab Storage Shards

## Sharding Overview

Sharding was introduced into GitLab in ver 8.10 with modifications in 8.13.
The fundamentals of sharding can be found in the GitLab Documentation under
[Repository storage paths](https://docs.gitlab.com/ce/administration/repository_storage_paths.html).

The summary of the documentation being as such:
1. Storage targets must be defined in the `gitlab.rb` configuration file within
the `git_data_dirs` paramiter.
1. Selection of targets for random new project assignment is done through the
'Application Settings' under the 'Admin Area'.

### GitLab Chef Configuration

Ceph and CephFS have three main components:

1. Clients that mount the storage via Kernel or FUSE mounts.
1. Monitoring and meta-data servers that tell the clients where to access files.
1. Back-end storage servers that have large amounts of disk space attached.


## Moving Data from Shards

All the worker nodes mount `/var/opt/gitlab/git-data-ceph` from the CephFS
servers.

The CephFS farm has three monitoring and metadata servers
(ceph-mon1, ceph-mon2, and ceph-mon3) and 10 back-end data storage servers
(ceph-osd[1-10]).

In CephFS speak the back in servers are 'osd'
Object Storage Daemons while the front-end servers are labeled `mon` for
monitoring and also serve the MDS (Meta Data Service) function.

The MDS function is what keeps a catalog of where all the file objects are
written across the OSD targets for CephFS.

### Warnings and Alerts

CephFS works by assigning CephFS clients resources called "inodes"
for file handling purposes. The current configuration allows for
2,000,000 inodes to be used by the entire cluster. From time to time
during heavy file activity a warning will be generated like:

`ceph-mon2.stor.gitlab.com CEPH_INODES is WARN - inodes - 1799207 of 2000000`

This is a standard process as when this occurs the Ceph MDS nodes request
resources back from the clients. This warning though should be an indicator
for you to check the logs on `log.gitlap.com` and check for `[WRN]` messages
on the ceph-mds[1-3] nodes. A warning message indicating that you need to take
action would look like:

`client.1844098 isn't responding to mclientcaps(revoke)`

When this happens look for open processes on the worker machines that would
be holding open resources against the CephFS file system (`/var/gitlab/git-data-ceph`).

### Checking the Health of the Service

From any of the monitor (ceph-mon) servers or osd servers (ceph-osd) issue the
following command to view the health:

`ceph health`

This will tell you the simple and immediate status of the cluster. For a more
in depth look at the health of the cluster issue:

`ceph status`

For a detailed look at the status of every disk within the Ceph cluster issue
the following:

`ceph osd tree`

Cephfs also offers tools that behave like standard unix tools, for example:

`ceph df`

Will print a storage usage report. This report can be turned into a json output
by adding `-f json`, such as:

`ceph df -f json`


### Adding a Worker Client

Add the role `gitlab-ceph-client` to the worker node. This will

* install the cephfs kernel drivers
* add the secret keys for mounting our ceph cluster
* mount the git-data-ceph volume up on the client
* create an fstab entry.

## Growth and Expansion Tasks

### Adding an OSD Server

The Azure machine for the build must be of type `Standard_DS14` and located in
the ARM resource side of the `eastus2` data center.

It should belong to the Resource Group `Ceph-Prod` and have two NICS associated with it.

The first NIC should be in the `CephFrontEnd` subnet with the second NIC being in the
`CephReplication` subnet as well as the `NSG-CephReplication` Network Security Group.

The primary NIC will have an IP address in the 10.42.1.0/24 network while the secondary
NIC will have an IP address in the 10.42.5.0/24 network.

It is important to note that the 10.42.5.0/24 network is for Ceph replication only and
is not reachable from the Azure "Classic" infrastructure resources.

Each OSD server should also have attached to it 25 1TB SSD disks.

24 of these disks will be user for data storage while one disk will
be used for Ceph Journaling (this disk is /dev/sdaa).


Once the node is built and communicating on the network, it is ready to be
added to the cluster. This task is done as the 'ceph-deploy' user on ceph-mon1
with configuration and keys located in the `/home/ceph-deploy/ceph-cluster directory`.

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
in the cluster. The formula for determing what the 'pg_num' value should be is
as follows:

Total PGs = ( OSD Drives * 100 ) / Replication Factor

This number is then raised to the next highest power of 2. Our current 'pg_num'
value is 8192. We arrive at this the following way:

240 * 100 / 3 = 8000, the next highest power of two available is 8192. In order to
set and rebalance the OSD's and CephFS service perform the following command:

`ceph osd pool set git_data pg_num 8192`

Once this is done the data will begin to be writeen to the new space, but data
replication will not happen until you adjust the gpg_num assocaited withi the OSD
target. To perform that action issue the following command:

`ceph osd pool set git_data gpg_num 8192`

The pg_num and gpg_num should always track with each other in lock-step.

### Adding Disks to an OSD Server

Don't - Each OSD server should be created with 24 1TB disk targets for storage,
when that is approaching full spin up another OSD server with another 24 1TB disks.

# Notes From the Field of Operation

## Kill the MDS server and see what happens
When you kill the active MDS server gracefully it sends immediate notifications to
the other MDS servers to start an election. The election process is near instant
and the MDS role is transferred to the elected MDS server. When you kill an MDS
server without letting it gracefully shutdown a timer is initiated between the
remaining MDS nodes for connectivity. At the expiration of that timer a new MDS
server is elected. During this time writes to the CephFS cluster are paused and
queued on the clients consuming the CephFS service. The MDS nodes beacon to the
Monitor servers every 4 seconds, this is tunable with the `mds_beacon_interval`
setting. Once an MDS node has missed the beacon interval the MDS grace timer
starts to declare the MDS node missing or malfunctioning. The default for this
grace period is 15 second, and is tunable with the `mds_beacon_grace` settings.

We have observed that gracefully killing an MDS server yields very little impact
to the CephFS cluster, even under active write and read scenarios. The non-graceful
removal of a MDS node results in a brief pause of IO across the clients consuming
CephFS and then a restart of data flow.

## Start killing OSDs until we go below quorum
Quorum for any OSD is a replication factor of three in our current configuration.
You can see the OSD participans of a placement group by issuing a `ceph pg map` command.
For example the OSD's that made up the placement group, or pg, 5.d85 can be found as such:

```
root@ceph-mon1:/home/jjn# ceph pg map 5.d85
osdmap e3166 pg 5.d85 (5.d85) -> up [118,45,69] acting [118,45,69]
root@ceph-mon1:/home/jjn#
```

This shows us that OSD 118, 45, and 69 make up the pg for which data may be a target.
We can see that all three of the OSDs are up, and in the next section we see that 118
is the acting (listed first) OSD and 45 and 69 are the replication peers for the factor
of three concurrency.

When we drop OSD concurrency below three for this pg, by disabling an OSD, the condition
goes from "active" with no warnings to "degraded" with the health of the ceph server
reporting that it is degraded and listing the specific OSD's that it is having a problem
with. When an OSD returns it will be marked as "recovering" while Ceph replicates the
data back to the OSD to establish quorum concurrency. This was observed to be an entirely
transparent process and had no bearing over performance or load on the CephFS cluster.

## Kill a whole node
This was done with `ceph-osd5.stor.gitlab.com` with zero notice to the CephFS cluster
on performance or scale. The Ceph monitors notices that the OSD node was gone, all
of the OSD objects that were associated with `ceph-osd5` were marked in degraded state
waiting for the OSD's to return. In this example we brought the OSD node back online
and a check was initiated, the OSD nodes were marked as "recovering" and the cluster
caught the OSD disk nodes up on the data that they had missed. This was a delta-copy
transaction because the disks were not NEW OSD replacements, but OSD disks coming back
on line into their same place. Had we opted NOT to bring the node back we could have
issued a "scrub" or a "crush reweight" that would have taken the data on the remaining
to OSD's that made up the missing pg quorums and redistributed it over the CephFS pool
to account for the fact that the OSD devices were not coming back but a data replication
factor of 3 was desired.

## Kill a monitor
The monitor service performs in a similar function to the MDS service, only they are
tasked with the entire health of the Ceph cluster and all functionality, this includes
not only monitoring the CephFS MDS functions, but also all of the Ceph, RADOS, and if
we had them RAGW gateways. They have a beacon interval of 1 second with each other
and a grace timeout of 4 seconds. Killing a monitor immediately shifts all heath
monitoring and administrative functions to the next available active monitor. There
was little to report here as the Ceph environment only needs one monitor and very
little state information is kept in them, they are active processing monitors that
watch and keep Ceph healthy as opposed to the MDS functions which catalog and store
metadata about where files are located on the Ceph RADOS pools.

## Inject latency between nodes to evaluate how the cluster behaves
When we first deployed Ceph we had a latency chasm of 5ms to 15ms between the clients
and the workers. This never resulted in data NOT being served to a client, however
data at peak latency times was not served in a timely enough fashion for the real-time
applications running on the clients depending upon the data. We have observed that
Ceph is tolerant of latency up to around 45ms for CephFS transactions and even greater
for Ceph RADOS replication. You will get warnings in the logs about delayed transaction
commits to Ceph peers, however functionality continues. The only issue where functionality
didn't continue was when we flat out firewalled a node and dropped packets, then the
time was started to disconnect the node from the rest of the Ceph farm. This setting
is tunable with `mds session autoclose` which has a default of 300 seconds, or 5 minutes
to a client that had disappeared mid-stream.

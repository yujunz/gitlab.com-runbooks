# CephFS Runguide

## CephFS Overview

CephFS is a distributed file system that is build on top of the Ceph block storage system. CephFS operates by presenting a posix layer to client systems that mount the storage.  This is accomplished by a native kernel driver extension for the client (there is also a FUSE driver, but we do not use this).

### CephFS Server Roles

Ceph and CephFS have three main components:

1. Clients that mount the storage via Kernel or FUSE mounts.
2. Monitoring and meta-data servers that tell the clients where to access files.
3. Back-end storage servers that have large amounts of disk space attached.


## CephFS Implimentation

All 20 of the worker nodes mount `/var/opt/gitlab/git-data-ceph` from the CephFS servers.  The CephFS farm has three monitoring and metadata servers (ceph-mon1, ceph-mon2, and ceph-mon3) and 10 back-end data storage servers (ceph-osd[1-10]).  In CephFS speak the back in servers are 'osd' Object Storage Daemons while the front-end servers are labeled `mon` for monitoring and also serve the MDS (Meta Data Service) function. The MDS function is what keeps a catalog of where all the file objects are written across the OSD targets.



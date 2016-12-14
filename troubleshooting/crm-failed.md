# Redis replication is lagging or has stopped

## First and foremost

*Don't Panic*

## Symptoms

You see alerts like

```
@channel db1.cluster.gitlab.com Heartbeat CRM Failed is UNKNOWN - check failed - please submit a crash report!

```

## Possible checks

* ssh into the host which generated the alert and check the actual replication status

```
$ crm status
Last updated: Wed Dec 14 08:33:51 2016        Last change: Mon Dec  5 19:50:26 2016 by hacluster via crmd on db1.cluster.gitlab.com
Stack: corosync
Current DC: db1.cluster.gitlab.com (version 1.1.14-70404b0) - partition with quorum
2 nodes and 1 resource configured

Online: [ db1.cluster.gitlab.com db2.cluster.gitlab.com ]

Full list of resources:

 gitlab_pgsql    (ocf::pacemaker:gitlab_pgsql):    Started db1.cluster.gitlab.com

Failed Actions:
* gitlab_pgsql_monitor_30000 on db1.cluster.gitlab.com 'not running' (7): call=33, status=complete, exitreason='none',
    last-rc-change='Fri Dec  9 15:07:04 2016', queued=0ms, exec=0ms
```

In this case we are crm resource must be cleanup.

## Resolution

* Run `crm resource cleanup gitlab_pgsql`
* After completion, please check status with `crm status`. Output should be:
```
Last updated: Wed Dec 14 08:51:20 2016        Last change: Wed Dec 14 08:51:11 2016 by hacluster via crmd on db1.cluster.gitlab.com
Stack: corosync
Current DC: db1.cluster.gitlab.com (version 1.1.14-70404b0) - partition with quorum
2 nodes and 1 resource configured

Online: [ db1.cluster.gitlab.com db2.cluster.gitlab.com ]

Full list of resources:

 gitlab_pgsql    (ocf::pacemaker:gitlab_pgsql):    Started db1.cluster.gitlab.com
```

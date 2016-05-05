# Postgresql replication is lagging or has stopped

## First and foremost

*Don't Panic*

## Symptoms

* Message in alerts channel _Check_MK: db4.cluster.gitlab.com service PostgreSQL\_replication\_lag is CRITICAL_
* CheckMK reporting [replication lag](https://checkmk.gitlap.com/gitlab/check_mk/index.py?start_url=%2Fgitlab%2Fcheck_mk%2Fview.py%3Ffilled_in%3Dfilter%26_transid%3D1462456721%252F49547588%26host_address%3D%26host_address_prefix%3Dyes%26opthost_group%3D%26hostgroups%3D%26opthost_contact_group%3D%26optservice_group%3D%26optservice_contact_group%3D%26svc_last_state_change_from%3D%26svc_last_state_change_from_range%3D3600%26svc_last_state_change_until%3D%26svc_last_state_change_until_range%3D3600%26svc_last_check_from%3D%26svc_last_check_from_range%3D3600%26svc_last_check_until%3D%26svc_last_check_until_range%3D3600%26host_tag_0_grp%3D%26host_tag_0_op%3D%26host_tag_0_val%3D%26host_tag_1_grp%3D%26host_tag_1_op%3D%26host_tag_1_val%3D%26host_tag_2_grp%3D%26host_tag_2_op%3D%26host_tag_2_val%3D%26host_regex%3D%26hostalias%3D%26hst0%3Don%26hst1%3Don%26hst2%3Don%26hstp%3Don%26is_summary_host%3D-1%26is_host_in_notification_period%3D-1%26service_regex%3DPostgreSQL_replication_lag%26service_display_name%3D%26service_output%3D%26check_command%3D%26st0%3Don%26st1%3Don%26st2%3Don%26st3%3Don%26stp%3Don%26hdst0%3Don%26hdst1%3Don%26hdst2%3Don%26hdst3%3Don%26hdstp%3Don%26is_service_acknowledged%3D-1%26is_service_scheduled_downtime_depth%3D-1%26is_service_in_notification_period%3D-1%26svc_notif_number_from%3D%26svc_notif_number_until%3D%26is_in_downtime%3D-1%26is_service_staleness%3D-1%26is_service_active_checks_enabled%3D-1%26is_service_notifications_enabled%3D-1%26is_service_is_flapping%3D-1%26is_aggr_service_used%3D-1%26site%3D%26is_host_favorites%3D-1%26is_service_favorites%3D-1%26search%3DSearch%26selection%3D4180c282-cbc6-4510-8323-faf9e2675b84%26view_name%3Dsearchsvc) as CRITICAL

## Possible checks

* ssh into the database host and check that the host is the actual replication slave using crm

```
# crm status
Last updated: Thu May  5 14:07:28 2016
Last change: Thu Apr 14 21:53:51 2016 via crmd on db4.cluster.gitlab.com
Stack: corosync
Current DC: db5.cluster.gitlab.com (167837716) - partition with quorum
Version: 1.1.10-42f2063
2 Nodes configured
1 Resources configured


Online: [ db4.cluster.gitlab.com db5.cluster.gitlab.com ]

 gitlab_pgsql (ocf::pacemaker:gitlab_pgsql):  Started db5.cluster.gitlab.com
```

In this case the active host is db5 (Current DC)

* Double check by assessing that there is no replication port open in this host

```
# iptables -t nat -L PREROUTING
Chain PREROUTING (policy ACCEPT)
target     prot opt source               destination
#
```

Not having any iptable routes means that this host is acting as the slave host, in this case this is DB means that this host is acting as the slave host, in this case this is DB4.

## Resolution

* In the slave host (check again to be sure) run the script `/root/gitlab_pgsql_recovery.sh`
* The script will **stop** the database and **remove** all data! Make sure to **not to execute it on the master node**,
and that master node is currently marked as active by pacemaker (crm).
* This script will ask about an *ip of primary postgresql server* and a *password for gitlab_replicator user*.
  * Get the ip by SSHing in the active database server
  * Get the password from the DevOps vault searching by _gitlab_replicator_
* Sample output

```
Enter ip of primary postgresql server
X.X.X.X
Enter password for gitlab_replicator@X.X.X.X
Stopping PostgreSQL
ok: down: logrotate: 0s, normally up
ok: down: postgresql: 1s
ok: down: remote-syslog: 0s, normally up
Backup postgresql.conf
Cleaning up old cluster directory
Starting base backup as replicator
could not change directory to "/root"
transaction log start point: 2C7/DE4DB588
0/99073646 kB (0%), 1/1 tablespace
transaction log end point: 2C9/984BED28
pg_basebackup: base backup completed
```

* This means that the replication is recovered, expect to see some alerts triggering until it gets in OK state.

### Troubleshooting

The recovery script may fail if the log is too far away or if the transaction log is being rotated while the replication is being recovered.

In this case the script with fail with the following error:
```
pg_basebackup: could not get transaction log end position from server: FATAL:  requested WAL segment 00000003000002C8000000E4 has already been removed
```

This can be managed just by running the script again and again until it catches up with the master log.

This is not a final solution and there are some ongoing tasks to improve the situation so this does not happen again, but it is not solved yet.

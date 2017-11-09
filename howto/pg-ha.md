# Componenets

All of the components are installed and configured via the omnibus installer.

There are two parts of the solution:
* failover
* identifying the current master

They are coupled via a consul service/watcher pattern.

## Failover
### postgresql
This is an obvious component. There are some caveats:

1. is that the `repmgr_funcs` have to be loaded with the shared libraries.

1. the `postgres[sql_replication_user]` has to be set to the repmgr user 
(by default **gitlab_repmgr**). This is the user used to setup replication 
after a fail-over orchestrated by **repmgrd**. 

1. The `sql_replication_user`'s password has to be manually configured on 
the primary, and a `.pgpass` file created manually on each node in the 
postgresql cluster. 
(e.g.
```
sudo gitlab-ctl write-pgpass --user gitlab_repmgr --hostuser gitlab-psql --database '*'
```
) this file lives under `/var/opt/gitlab/postgresql/.pgpass`

1. the `postgres[pgbouncer_user_password]` has to be set to the md5sum of 
the `pgbouncer`'s password. This creates the user pgbouncer uses to lookup the 
user/password of servers which connect to it. If this is not set correctly, there will be
errors such as the following in the logs:

```
2017-10-31_13:57:10.31264 postgres-01 postgresql: 2017-10-31 13:57:10 GMT [20564]: [1-1] FATAL:  password authentication failed for user "pgbouncer"
2017-10-31_13:57:10.31287 postgres-01 postgresql: 2017-10-31 13:57:10 GMT [20564]: [2-1] DETAIL:  Password does not match for user "pgbouncer".
```



### repmgr and repmgrd

[config options](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template#L1638)

Omnibus creates the **repmgr** database and user, which is used to track primary/secondary 
servers. (by default `sudo gitlab-psql gitlab_repmgr`) Looking at the table `repmgr_gitlab_cluster.repl_nodes` 
will tell use about the cluster setup:

```
gitlab_repmgr=# select * from repmgr_gitlab_cluster.repl_nodes ;
    id     |  type   | upstream_node_id |    cluster     |             name              |                                       conninfo                                       |       slot_name       | priority |
 active 
-----------+---------+------------------+----------------+-------------------------------+--------------------------------------------------------------------------------------+-----------------------+----------+
--------
 926049637 | master  |                  | gitlab_cluster | db.gitlab.com                 | host=db.gitlab.com port=5432 user=gitlab_repmgr dbname=gitlab_repmgr                 | repmgr_slot_926049637 |      100 |
 t
 808870195 | standby |        926049637 | gitlab_cluster | postgres-01.gitlab.com        | host=postgres-01.gitlab.com port=5432 user=gitlab_repmgr dbname=gitlab_repmgr        | repmgr_slot_808870195 |      100 |
 t
 842491233 | standby |        926049637 | gitlab_cluster | postgres-02..gitlab.com       | host=postgres-02.gitlab.com port=5432 user=gitlab_repmgr dbname=gitlab_repmgr        | repmgr_slot_842491233 |      100 |
 t
```
This includes the topology (who is a slave of whom), the replication slot names (which repmgrd will use to configure slots on the new master), the conninfo (which repmgr uses to communicate to the respective host). 

    sudo gitlab-ctl repmgr cluster show

Will also show a quick overview of this information. 

repmgr keeps track of these things while repmgrd is responsible for ensuring the master is availible. 
If it detects a failure, it will cause an internal election, promote one of the standby nodes, and
reconfigure the other nodes to follow the new master. On the new master, it will setup the 
replication slots in accordance with the `slot_name` column above:

```
select * from pg_replication_slots ;
       slot_name       | plugin | slot_type | datoid | database | active | active_pid | xmin | catalog_xmin |  restart_lsn  | confirmed_flush_lsn 
-----------------------+--------+-----------+--------+----------+--------+------------+------+--------------+---------------+---------------------
 repmgr_slot_912536887 |        | physical  |        |          | t      |      44401 |      |              | 2858/33000060 | 

```

As well as configure the new standby to follow the master in the `/var/opt/gitlab/postgresql/data/recovery.conf`, 
by creating the entry accordingly:

```
standby_mode = 'on'
primary_conninfo = 'user=gitlab_repmgr port=5432 sslmode=prefer sslcompression=1 host=postgres01.gitlab.com application_name=postgres02.gitlab.com password=XXX'
recovery_target_timeline = 'latest'
primary_slot_name = repmgr_slot_912536887
```


## identifying current master

This is the second part of the omnibus solution. It deals with reconfiguring pgbouncer (the connection
pooler for postgresql) to connect to the new primary db in the case of a failover.

### consul

[config options](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template#L1683)

In order to communicate with our consul cluster, the omnibus consul service has to have the 
configuration in the `gitlab.rb`

```
          "configuration": {                         
            "retry_join": [                          
              "1.2.3.101",                        
              "1.2.3.102",                        
              "1.2.3.103"                         
            ],                                       
            "datacenter": "east-us-2",               
            "encrypt": "random-encrypt",                                                
            "key_file": "/path/to/consul.key",                                             
            "cert_file": "/path/to/consul.crt",                                              
            "ca_file": "/path/to/chain.crt"
```
Follow along in the log file: `/var/log/gitlab/consul/current`.

A normal log file would look like this:

```
2017-10-30_17:40:34.03343 ==> Starting Consul agent...                                                    
2017-10-30_17:40:34.11385 ==> Consul agent running!  
2017-10-30_17:40:34.11420            Version: 'v0.9.0'
2017-10-30_17:40:34.11439            Node ID: '40c0ddb8-3b03-abcc-6d69-be250fb5cfeb'
2017-10-30_17:40:34.11457          Node name: 'FQDN'
2017-10-30_17:40:34.11474         Datacenter: 'east-us-2'
2017-10-30_17:40:34.11561             Server: false (bootstrap: false)
2017-10-30_17:40:34.11585        Client Addr: 127.0.0.1 (HTTP: 8500, HTTPS: -1, DNS: 8600)
2017-10-30_17:40:34.11599       Cluster Addr: ##IP## (LAN: 8301, WAN: 8302)
2017-10-30_17:40:34.11616     Gossip encrypt: true, RPC-TLS: false, TLS-Incoming: false
2017-10-30_17:40:34.11630 
2017-10-30_17:40:34.11644 ==> Log data will now stream in as it occurs:
2017-10-30_17:40:34.11658 
2017-10-30_17:40:34.11675     2017/10/30 17:40:34 [INFO] serf: EventMemberJoin: ###FQDN IP###
2017-10-30_17:40:34.11692     2017/10/30 17:40:34 [INFO] agent: Started DNS server 127.0.0.1:8600 (udp)
2017-10-30_17:40:34.11706     2017/10/30 17:40:34 [INFO] agent: Started DNS server 127.0.0.1:8600 (tcp)
2017-10-30_17:40:34.11719     2017/10/30 17:40:34 [INFO] agent: Started HTTP server on 127.0.0.1:8500
2017-10-30_17:40:34.12304     2017/10/30 17:40:34 [INFO] agent: Joining cluster...
2017-10-30_17:40:34.12328     2017/10/30 17:40:34 [INFO] agent: (LAN) joining: [IPS-FOR-CONSUL-SERVERS]
2017-10-30_17:40:34.12360     2017/10/30 17:40:34 [WARN] manager: No servers available
2017-10-30_17:40:34.12385     2017/10/30 17:40:34 [ERR] agent: failed to sync remote state: No known Consul servers
2017-10-30_17:40:34.12490     2017/10/30 17:40:34 [WARN] manager: No servers available
```

followed by these messages from the `serf` protocol for each server connected to consul:
```
2017-10-30_17:40:34.13186     2017/10/30 17:40:34 [INFO] serf: EventMemberJoin: ###FQDN OF NODES###
```


#### on the db

Omnibus offers a consul [service](https://www.consul.io/docs/agent/services.html) definition 
to verify what server is the current primary. The `gitlab_consul` database user has to have 
read access to the `repmgr_gitlab_cluster.repl_nodes` so it can find who is the current 
master, and (in the case of a primary) ensure that the local db is also the latest 
successful db in the `repmgr_gitlab_cluster.repl_events`. 

If you are on a primary and there are warning messages in the log file, verify that there are no permission 
errors in the Postgresql log files. It is possible that the `gitlab_consul` database user does not 
have sufficient access to execute the service check.

An example of these errors is:

```
2017-10-31_14:28:20.93009 postgres-01 postgresql: 2017-10-31 14:28:20 GMT [40758]: [1-1] ERROR:  permission denied for schema repmgr_gitlab_cluster at character 18
2017-10-31_14:28:20.93022 postgres-01 postgresql: 2017-10-31 14:28:20 GMT [40758]: [2-1] STATEMENT:  SELECT name FROM repmgr_gitlab_cluster.repl_nodes WHERE type='master' AND active != 'f'
```

When viewing the state of this service in consul, there will always be failing nodes: these are the 
secondaries, only the primary should be succeeding on the service.

#### on the pgbouncer

On the pgbouncer hosts, consul is configured to [watch](https://www.consul.io/docs/agent/watches.html) the 
state of the `postgres` [service](https://www.consul.io/docs/agent/services.html). This means when 
the service changes, the omnibus consul instance will trigger a fail-over notification 
on the pgbouncer. Information about this can be found in the `/var/log/gitlab/consul/failover_pgbouncer.log` 
log file. When a fail-over is triggered, consul will get the new primary's name from the service 
definition, and pipe that to the pgbouncers `database.ini` snippet, reloading the pgbouncer 
to read the new settings. In the `failover_pgbouncer.log` this will look like this:

```
E, [2017-10-31T14:46:11.031750 #29504] ERROR -- : No master found
I, [2017-10-31T14:46:12.058417 #29512]  INFO -- : Found master: db.gitlab.com
I, [2017-10-31T14:46:12.059157 #29512]  INFO -- : Running: gitlab-ctl pgb-notify --newhost db.gitlab.com --user pgbouncer --hostuser gitlab-consul
```

The consul controlled `database.ini` file lives here: `/var/opt/gitlab/consul/database.ini`. It is created 
by mixing the *raw* json configuration from `/var/opt/gitlab/consul/database.json` with the FQDN from consul 
(`db.gitlab.com` in the example above).

Since the consul user needs to be able to speak to pgbouncer directly, it needs a `.pgpass` file to be created:

```
sudo gitlab-ctl write-pgpass --host 127.0.0.1 --database pgbouncer --user pgbouncer --hostuser gitlab-consul
```

This file can be found here: `/var/opt/gitlab/consul/.pgpass`

Since the watcher is triggered anytime the consul service changes, it is possible that certain errors can
occure when there are short network outages. Consul recongnizes these as changes in the service, so it 
triggers a reconfiguration. In such cases we use `exit status 4` to signify *no master found* and dont actually
let anything get triggered:

```
2017-11-09_02:36:10.00165     2017/11/09 02:36:10 [ERR] agent: Failed to invoke watch handler '/var/opt/gitlab/consul/scripts/failover_pgbouncer': exit status 4
```


### pgbouncer

Pgbouncer includes the consul controlled ini file (`/var/opt/gitlab/consul/database.ini`) in its configuration, 
which can be found here: `/var/opt/gitlab/pgbouncer/pgbouncer.ini`.




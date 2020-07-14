# Check the status of transaction wraparound Runbook

Here the link to the video of the [runbook simulation](https://youtu.be/lR-yjLbRrmk).

## Intro
The autovacuum process executes a "special" maintenance task called **[to prevent wraparound](https://www.postgresql.org/docs/11/routine-vacuuming.html#VACUUM-FOR-WRAPAROUND)** or **[wraparound protection](https://www.postgresql.org/docs/11/routine-vacuuming.html#VACUUM-FOR-WRAPAROUND)** on tables that the TXID reaches the [autovacuum_freeze_max_age](https://postgresqlco.nf/en/doc/param/autovacuum_freeze_max_age/). Sometimes this activity can be annoying in a high workload on the database server due to the expense of consuming additional resources. A manual `frozen vacuum` command helps avoid this "situation", but running `frozen vacuum` on the entire database can slow down the database server, hence the importance of monitoring and executing it by table(especially on big tables) it is a smart decision


## Verify the status wraparound on each table in GitLab

It is important to monitor the `TXID` of the tables to check if this table is near to a wraparound, with the following [script](scripts/wraparound.sh) you can check the tables' status and generate `FREEZE` command, please execute on the `leader` (primary) server:

You can check the `help` and see the parameters for the script

```       
sh wraparound.sh -h

Script for check wraparound status and generate FREEZE command 
wraparound.sh  -m check -p 95
options
 mode: -m check/generate (default check)
 size: -s size threshold of tables to check/generate (default 10000000000 [10GB])
 percent: -p % threshold of age (default 95 )

```

Only 9% of tables exceeding 10GB of size, and these tables are 97% size of the whole database  

**Mode options**
* check: Show which tables are exceeding the threshold of -s(size) and -p (percent of TXID age)
* generate: Return commands to run to prevent wraparound tables from exceeding   the threshold of -s(size) and -p (percent of TXID age)
 
```


#check tables with more than 95 % of TXID and more than 10GB
sh wraparound.sh -p 95 -m check -s 10000000000
```

You will get an output similar to:
```
 mode: check, size: 10000000000, percent: 95
   full_table_name   | pg_size_pretty | freeze_age | percent 
---------------------+----------------+------------+---------
 push_event_payloads | 72 GB          |  188675977 |      98
 notes               | 431 GB         |  184676635 |      96
(2 rows)

```

The previous query filter the tables bigger than 10GB and more than 95% of freeze_age (can change if needed)

## Execute `FREEZE` maintenance task in  GitLab
To execute the `FREEZE` maintenance task you can get the commands from the following query:

```
sh wraparound.sh -p 95 -m  generate -s 10000000000
```

The previous query returns the `FREEZE` commands for maintenance (can filter by tablename)

You will get an output similar to:
```        
mode: generate, size: 10000000000, percent: 95
                            command                             
----------------------------------------------------------------
 VACUUM FREEZE ANALYZE push_event_payloads; select pg_sleep(2);
 VACUUM FREEZE ANALYZE notes; select pg_sleep(2);
(2 rows)


```

You can execute the previous commands in the `leader`(primary) server  on off-peak times so as not to impact the primary server due to the expense of consuming additional IO resources.

for example:
```
gitlabhq_production=# VACUUM FREEZE ANALYZE system_note_metadata; select pg_sleep(2);
VACUUM
 pg_sleep 
----------
 
(1 row)

```


Please, when executing these commands see the [dashboard](https://dashboards.gitlab.net/d/patroni-main/patroni-overview?orgId=1) to monitoring patroni


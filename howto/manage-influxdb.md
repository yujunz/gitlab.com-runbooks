# InfluxDB

## Connect to the DB

1. ssh into the influxdb running host (performance-new at the time of writing this)
1. run a naked `influxdb` command

## Wipe data

1. connect to influxdb
1. switch to the database you want to wipe with `use database` (`show databases` will tell you which DBs are available)
1. wipe series with `drop series from /.*/` (possible dataloss, handle with care.
1. wipe measurements with `drop measurements from /.*/` (possible dataloss, handle with care.

## Set a retention policy

1. connect to influxdb
1. switch to the database you want to wipe with `use database` (`show databases` will tell you which DBs are available)
1. invoke `create retention policy "<policy_name>" on "<database_name>" duration <time literal, like: 1d> replication 1`

# PostgreSQL

## So your Postgres server has run out of disk space....

* Don't panic -- Postgres should handle the situation cleanly

* Check `tail /var/log/gitlab/postgresql/current`
* Check `select * from pg_replication_slots`
* Check `du -sh /var/opt/gitlab/postgresql/data/pg_xlog`

In fact often Postgres will just generate regular transaction ERRORs
and continue without crashing at all. This is especially true if it's
mainly running read-only queries. Whent there is disk space available
again it will continue as if nothing happened. So if the server is
still up focus on adding space or finding the log files or other files
consuming space.

If it cannot write XLOG then it will crash. The log files will show a
`PANIC` log message.  But when the disk space is free again it should
start up and do regular crash recovery so still focus on adding space
or identifying the top consumer of space and cleaning it up.

* If the `pg_xlog` (or `pg_wal` in PG 11+) directory is the problem:

If there's a replication slot that has `active` false and has a
markedly old `restart_lsn` then it may be forcing Postgres to keep
lots of old xlog around. 

If the replica cannot be resurrected (or if there are other healthy
replicas and you would rather get the primary back sooner and lose
this one) then run `select pg_drop_replication_slot('slot_name');`

If the server has already crashed then the best strategy is to find a
few gigabytes to remove, start it up and then run
`pg_drop_replication_slot` as above. On our servers there is a file
`DO_NOT_MOVE_THIS_FILE` which you can remove to create space to do
this.

Failing that you may have to remove old xlog files manually. This is
extremely hazardous as if you remove a needed file the server will be
lost and unable to recover.

You can check the log files for the last few checkpoint logs or you
can run pg_controldata:

```
$ /opt/gitlab/embedded/postgresql/bin/pg_controldata /var/opt/gitlab/postgresql/data

Latest checkpoint location:           2B78/E30A3218
Prior checkpoint location:            2B78/DD37A880
Latest checkpoint's REDO location:    2B78/DF728AB8
Latest checkpoint's REDO WAL file:    0000000400002B78000000DF
```

*WARNING*: Do not under any circumstances remove any xlog files newer
than these xlog locations. The "Latest checkpoint's REDO WAL file" is
the simplest one to follow as it's the actual file name. However
ideally you should retain more than that. Just remove a minimum number
of the oldest files.

*WARNING*: Do not remove any files that end in `.history`. These files
are needed for standbys to follow the wal through timeline forks. A
new standby will not start up if this file is not present.

## Reconstruct a standby after the xlog has been pruned on the primary

If you see log messages like:

```
2018-01-29_10:13:01.21015 postgres02 postgresql: 2018-01-29 10:13:01 GMT [91066]: [1-1] LOG:  started streaming WAL from primary at 2B44/23000000 on timeline 4
2018-01-29_10:13:01.21047 postgres02 postgresql: 2018-01-29 10:13:01 GMT [91066]: [2-1] FATAL:  could not receive data from WAL stream: ERROR:  requested WAL segment 0000000400002B4400000023 has already been removed
```

Then the standby is lost due to the xlog on the primary being
pruned. 

If the standby is properly configured it should be able to retrieve
the archived logs from blob storage. Currently this requires
installing the WAL-E PGP private key in the agent in order for that to
work.

* Start a tmux session -- the standby clone will take several hours
* Ensure you're on the correct replica host!
* Ensure the database is shut down on the replica
* `watch du -sh /var/opt/gitlab/postgresql/data`
* `tail -f /var/log/gitlab/postgresql/current `
* `rm -r /var/opt/gitlab/postgresql/data/*`
* `/opt/gitlab/bin/gitlab-ctl repmgr standby clone postgres01.db.stg.gitlab.com`
* `/opt/gitlab/bin/gitlab-ctl start postgresql`
* `/opt/gitlab/bin/gitlab-ctl repmgr standby register`

While the server is starting up -- especially for the first time -- it
is normal to see many log entries like this which simply indicate that
a client has tried to connect before the server is finished starting
up:

```
2018-01-30_01:00:09.80433 postgres02 postgresql: 2018-01-30 01:00:09 GMT [110492]: [1-1] FATAL:  the database system is starting up
```

When it's ready you should see log entries like this when the database starts up:

```
2018-01-30_01:00:11.58219 postgres02 postgresql: 2018-01-30 01:00:11 GMT [110184]: [4-1] LOG:  consistent recovery state reached at 2B79/D994F010
2018-01-30_01:00:11.58246 postgres02 postgresql: 2018-01-30 01:00:11 GMT [110182]: [1-1] LOG:  database system is ready to accept read only connections
2018-01-30_01:00:11.65525 postgres02 postgresql: 2018-01-30 01:00:11 GMT [110525]: [1-1] LOG:  started streaming WAL from primary at 2B79/DA000000 on timeline 4
```

If you see log entries like this:

```
2018-01-29_21:11:47.51934 postgres02 postgresql: 2018-01-29 21:11:47 GMT [36073]: [2-1] LOG:  invalid checkpoint record
2018-01-29_21:11:47.51944 postgres02 postgresql: 2018-01-29 21:11:47 GMT [36073]: [3-1] FATAL:  could not locate required checkpoint record
2018-01-29_21:11:47.51948 postgres02 postgresql: 2018-01-29 21:11:47 GMT [36073]: [4-1] HINT:  If you are not restoring from a backup, try removing the file "/var/opt/gitlab/postgresql/data/backup_label".
```

Then you are missing the `*.history` file. It may have been removed in
an overzealous attempt to free space by removing xlog files. Don't
panic, you can cons one up manually without too much difficulty, at
least in the simple case where there's only one timeline. In that case
you just need a single dummy entry in the timeline history file
telling the standby to follow that timeline.

The following example says that the switch from timeline 3 (the parent
timeline) to timeline 4 (the current timeline) occurred right at the
start of the oldest xlog file that was retained. 

You can pick any xlog time older than the checkpoint that the
pg_basebackup was taken from. It may be easiest to just put 0/0 in
fact -- we should test that.

```
$ ls /var/opt/gitlab/postgresql/data/pg_xlog | head
0000000400002B780000003B
0000000400002B7800000086
0000000400002B78000000D1
0000000400002B790000001C
0000000400002B7900000067
0000000400002B79000000B2
0000000400002B77000000F1
0000000400002B780000003C
0000000400002B7800000087

$ cat > 00000004.history
3   2B78/3B000000   manually recreated timeline history
^D
```

You'll probably want to do this on the *primary* and then repeat the
`repmgr standby clone` (after clearing out the `data` directory). 

You may be able to just add it to the standby and restart however make
sure the standby is actually still in standby mode and hasn't
accidentally been promoted. (Run `pg_controldata` and check the
`Database cluster state`).

If you see something like:

```
2018-01-30_00:48:41.54672 postgres02 postgresql: 2018-01-30 00:48:41 GMT [105225]: [3-1] FATAL:  invalid data in history file "pg_xlog/00000004.history"
2018-01-30_00:48:41.54687 postgres02 postgresql: 2018-01-30 00:48:41 GMT [105225]: [4-1] HINT:  Timeline IDs must be less than child timeline's ID.
```

it indicates you've entered the *current* timeline (4 above) rather than the
*parent* timeline (3 above) in the history file.


If it succeeds you should see something like:

```
2018-01-30_01:00:11.58219 postgres02 postgresql: 2018-01-30 01:00:11 GMT [110184]: [4-1] LOG:  consistent recovery state reached at 2B79/D994F010
2018-01-30_01:00:11.58246 postgres02 postgresql: 2018-01-30 01:00:11 GMT [110182]: [1-1] LOG:  database system is ready to accept read only connections
2018-01-30_01:00:11.65525 postgres02 postgresql: 2018-01-30 01:00:11 GMT [110525]: [1-1] LOG:  started streaming WAL from primary at 2B79/DA000000 on timeline 4
```

Don't forget to run `gitlab-ctl repmgr standby register` to add the
standby to the repmgr cluster. Run `gitlab-ctl repmgr cluster show` to
verify that it's active.

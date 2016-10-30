# Errors are reported in LOG files

## First and foremost

*Don't Panic*

## Symptoms

* Message in alerts channel:

```
@channel ceph-mon1.stor.gitlab.com Ceph_status is WARN - HEALTH WARNING: mds0: Client worker20.cluster.gitlab.com failing to respo
```

## Resolution

1. Check to see if there are any stuck git-upload-pack processes:

    ```
    $ bundle exec knife ssh -a ipaddress role:gitlab-cluster-worker 'ps -ef | grep upload-pack | grep gitlab-ce.git | wc -l'
    ```

2. If you see an unusually high number (e.g. > 20) for many of the machines,
login to one of the machines and verify the process hasn't finished.

3. To kill all the stuck processes, run:

    ```
    $ bundle exec knife ssh -a ipaddress role:gitlab-cluster-worker "ps aux | grep git-upload-pack | grep gitlab-ce.git | grep -v grep | awk -e '{ print \$2 }' | xargs sudo kill"
    ```

## Message about PG State

 * You'll see a message in the alerts channel like such:

 ```
 @channel ceph-mon1.stor.gitlab.com Ceph_status is CRIT - HEALTH ERROR: 1 pgs inconsistent: 1 scrub errors:
 ```

## Resolution

1. Obtain the current PG(s) that are having the issue by using the `ceph health detail` command on one of the `ceph-mon[1-3]` servers:

    ```
    $ ceph health detail
    HEALTH_ERR 1 pgs inconsistent; 1 scrub errors
    pg 5.1b0 is active+clean+inconsistent, acting [17,176,61]
    1 scrub errors
    ```

2. Now that we have the PG in question, let's ask Ceph to repair the PG in question:

    ```
    # ceph pg repair 5.1b0
    ```

3. This action should take less than a couple of minutes, upon which you can check the status with `ceph -s`

    ```
    # ceph -s
    cluster c309a189-ca58-47f3-8558-e03f78572b06
     health HEALTH_OK
     monmap e5: 3 mons at {ceph-mon1=10.42.1.11:6789/0,ceph-mon2=10.42.1.12:6789/0,ceph-mon3=10.42.1.13:6789/0}
            election epoch 776, quorum 0,1,2 ceph-mon1,ceph-mon2,ceph-mon3
      fsmap e30156: 1/1/1 up {0=ceph-mon1=up:active}, 2 up:standby
     osdmap e48153: 276 osds: 276 up, 276 in
            flags sortbitwise
      pgmap v5492626: 16384 pgs, 2 pools, 14394 GB data, 67360 kobjects
            46513 GB used, 230 TB / 275 TB avail
               16383 active+clean
                   1 active+clean+scrubbing
  client io 35781 kB/s rd, 6234 kB/s wr, 379 op/s rd, 147 op/s wr
    ```


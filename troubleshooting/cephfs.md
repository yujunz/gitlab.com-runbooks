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

## Reason

Free disk space on runners cache node is less than 20%.

## Possible checks

* SSH to the `runners-cache-X.gitlab.com`.
* Check available space by executing `df -h | grep /dev/vda1`.
* Check which directory is consuming the largest space by executing `cd /; du -h -d 1 -x`, `-x` limits to a single filesystem to prevent reaching larger drives
  * Most of the cases it will be either `/opt/gitlab/cache/` or `/opt/gitlab/registry`.
  * Some hosts mount the `cache`, AKA `minio` and `registry` folders in `/opt/gitlab/` using a different drive.

## Fixing `/opt/gitlab/cache/.minio.sys` or `/opt/gitlab/cache/runner/runner`

> Adjust these commands depending on the filesystem structure.

You can delete files from cache which is more three days old by running following command

```
sudo find /opt/gitlab/cache/ -mindepth 3 -maxdepth 6 -ctime -3 -exec rm -rf {} \;
```

Or more than two days old

```
sudo find /opt/gitlab/cache/ -mindepth 3 -maxdepth 6 -ctime -2 -exec rm -rf {} \;
```

## Fixing `/opt/gitlab/registry`

First, stop the registry container

```
sudo docker stop registry
```

then remove everything in `/opt/gitlab/registry`

```
sudo rm -r /opt/gitlab/registry/*
```

and finally start the registry container again

```
sudo docker start registry
```


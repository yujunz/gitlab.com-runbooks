## Reason

Free disk space on runners cache node is less than 20%.

## Possible checks

SSH to the `runners-cache-1.gitlab.com`. You can check available space by executing `df -h | grep /dev/vda1`.
Check which directory is consuming the largest space by executing `du -h -d 1 /opt`, most of the cases it will
be either `/opt/minio` or `/opt/registry`.

## Fixing `/opt/minio`

On host there is cron job which every hour deletes files from cache which is more than 4 days old.
But you can delete files from cache which is more three days old by running following command

```
sudo find /opt/minio/runner/runner/ -mindepth 3 -maxdepth 6 -ctime -3 -exec rm -rf {} \;
```

Or more than two days old

```
sudo find /opt/minio/runner/runner/ -mindepth 3 -maxdepth 6 -ctime -2 -exec rm -rf {} \;
```

## Fixing `/opt/registry`

First, stop the registry container

```
sudo docker stop registry
```

then remove everything in `/opt/registry`

```
sudo rm -r /opt/registry/*
```

and finally start the registry container again

```
sudo docker start registry
```

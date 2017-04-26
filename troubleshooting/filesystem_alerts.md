# Errors are reported in LOG files

## First and foremost

*Don't Panic*

## Symptoms

You're likely here because you saw a message saying "Really low disk space left on _path_ on _host_: _very low number_%".

Not a big deal (well, usually). There are two possible causes:
1. A volume got full and we need to figure out how to make some space.
1. A process is leaking file handlers.

The latter is a little trickier. Check out [how to fix file handler leaks](#file-handler-leaks) later in this page.
There are many instances where the solution is well known and it only takes a single command to fix. Keep reading.

## Resolution

First, check out if the host you're working on is one of the following:

### Well known hosts

#### performance.gitlab.net

This alerts triggered on `/var/lib/influxdb/data` and `influxdb` is likely to be the culprit. Apparently there is a file handler leak somewhere and this happens regularly.

Take a look at [how to fix file handler leaks](#file-handler-leaks) later in this page. You can restart influxdb with `sudo service influxdb restart`.

#### worker*.gitlab.com

It's probably nginx leaking file handlers.

Take a look at [how to fix file handler leaks](#file-handler-leaks) later in this page. You can restart nginx with `sudo gitlab-ctl restart nginx`.

### Anything else

Check out if kernel sources have been installed and remove them:
```
sudo apt-get purge linux-headers-*
```

You can also run an autoremove:
```
sudo apt-get autoremove
```

Next thing to remove to free up space is old log files. Run the following to delete all logs older than 2 days:

```
sudo find /var/log/gitlab -mtime +2 -exec rm {} \;
```

If that didn't work you can also remove temporary files:

```
$ sudo find /tmp -type f -mtime +2 -delete
```

If you're still short of free space you can try to delete everything older than 10 minutes.

```
sudo find /var/log/gitlab -mmin +10 -exec rm {} \;
```

Finally you can try to remove cached temp files by restarting services.

### File handler leaks

This happens when a process deletes a file but doesn't close the file handler on it. The kernel then can't see that space as free as it's still been held by the process.

You easily can check this with `sudo lsof | grep deleted`. If you see many deleted file handlers held by the same process you can fix this by restarting it.

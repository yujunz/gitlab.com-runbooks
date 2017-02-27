# Errors are reported in LOG files

## First and foremost

*Don't Panic*

## Symptoms

* Message in alerts channel _Check_MK: service fs_/ is CRITICAL_

## Resolution

* Most likely there are old accumulated log files. ssh into the worker giving
the alerts and run the following to delete all logs older than 2 days:

```
$ sudo find /var/log/gitlab -mtime +2 -exec rm {} \;
```

* Another option is to also remove temporary files

```
$ sudo find /tmp -type f -mtime +2 -delete
```

* If commands above do not free enough space, as an option you can try to delete everything older than 10 minutes.

```
sudo find /var/log/gitlab -mmin +10 -exec rm {} \;
```

* Also you can try to remove cached temp files by restarting services

On workers it is usually `nginx`:
```
sudo gitlab-ctl restart nginx
```

On performance.gitlab.net it is `influxdb`:
```
sudo service influxdb restart
```

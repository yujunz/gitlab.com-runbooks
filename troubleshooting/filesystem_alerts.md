# Errors are reported in LOG files

## First and foremost

*Don't Panic*

## Symptoms

* Message in alerts channel _Check_MK: service fs_/ is CRITICAL_

## Resolution

* Most likely there are old accumulated log files. ssh into the worker giving
the alerts and run the following to delete all logs older than 5 days:

```
$ sudo find /var/log/gitlab -mtime +5 -exec rm {} \;
```

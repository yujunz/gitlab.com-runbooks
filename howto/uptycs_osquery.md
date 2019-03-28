# Overview

Security is using the [Uptycs](https://www.uptycs.com/) Security Analytics Platform which is based on [osquery](https://osquery.io/).

The osqueryd daemon is rolled out to staging and production by the [gitlab-uptycs cookbook](https://gitlab.com/gitlab-cookbooks/gitlab-uptycs) and is downloading it's configuration profile and sending query results from/to gitlab.uptycs.io which is controlled by the security team.

As osqueryd can consume many system resources - depending on configuration profile and node workload - we added [process_exporter metrics](https://prometheus.gprd.gitlab.net/graph?g0.range_input=30m&g0.expr=rate(namedprocess_namegroup_cpu_user_seconds_total%7Bgroupname%3D%22osqueryd%22%7D%5B5m%5D)&g0.tab=0) for the `osqueryd` process.

See [troubleshooting](../troubleshooting/uptycs_osqueryd.md) for common problems.

## Service Management

The Uptycs service on endpoints runs as `osqueryd` and is controlled  as a systemd service:

```
[paul@pharrison-scan-target]~:  sudo service osqueryd status
● osqueryd.service - The osquery Daemon
   Loaded: loaded (/usr/lib/systemd/system/osqueryd.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2019-01-28 13:24:07 UTC; 2 weeks 1 days ago
 Main PID: 516 (osqueryd)
    Tasks: 22 (limit: 4915)
   CGroup: /system.slice/osqueryd.service
           ├─  516 /usr/bin/osqueryd --flagfile /etc/osquery/osquery.flags --config_path /etc/osquery/osquery.conf
           └─13316 /usr/bin/osqueryd
```

AS SUCH it can be controlled like any other systemd service:

```
Usage: /etc/init.d/osqueryd {start|stop|status|restart}
```

### Stopping osqueryd

In the event the `osqueryd` service is found to be causing problems it can be disabled using:

```
sudo service osqueryd stop
```

### Starting osqueryd

Similar to stopping the `osqueryd` service, it can be enabled easily using:

```
sudo service osqueryd start
```

### Disable/Enable osqueryd

Disabling `osqueryd` from auto-starting on boot is slightly different:

```
sudo systemctl disable osqueryd
```

Enabling is pretty much the same way:

```
sudo systemctl enable osqueryd
```

### Uninstall osqueryd

The `osqueryd` install/uninstall is managed by the aptitude package manager, and easy to uninstall:

```
sudo apt-get remove osquery
```

If we're looking to remove the config files and ancillary data left by the package:

```
sudo apt-get purge osquery
```

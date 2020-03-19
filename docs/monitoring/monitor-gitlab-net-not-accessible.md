# monitor.gitlab.net not accessible or return 5xx errors

## Possible checks

1. Check nginx - `sudo service nginx status`

Example output if service is down

```
Active: stopped (down) since Wed 2017-01-25 05:36:25 UTC; 2 days ago
```

2. Check grafana - `sudo service grafana-server status`

Example output if service is down

```
Active: stopped (down) since Wed 2017-01-25 05:36:25 UTC; 2 days ago
```

3. Also check logs for corresponding services.

## Resolution

If service is down, then restart/start it with the command - `sudo service restart nginx` or `sudo service restart grafana`.

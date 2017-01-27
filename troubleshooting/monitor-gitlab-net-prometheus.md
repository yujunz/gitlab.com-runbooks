# Prometheus on monitor.gitlab.net is down

## Possible checks

1. Try check status of service with `sudo sv status prometheus`

Example output if service is down

```
down: prometheus: (pid 31123) 156007s; run: log: (pid 1312) 2081905s
```

2. Also check logs - `sudo less /var/log/prometheus/prometheus/current`.

## Resolution

If service is down, then restart/start it with the command - `sudo sv restart prometheus`.

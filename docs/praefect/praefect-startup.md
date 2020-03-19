# Praefect is down

## Symptoms

* Message in prometheus-alerts _Praefect is down on [hostname]_

## 1. Check the Praefect Logs

- Check [Sentry](https://sentry.gitlab.net/gitlab/praefect-production/) for unusual errors
- Check the Praefect service logs on the affected host
  - grep for `SIGSEGV` or `SIGILL` in `/var/log/gitlab/praefect/`

## 2. Ensure that the Praefect server process is running

- Can you see the process in `ps aux | grep praefect`?
- Is the prometheus port responding: Does `curl https://localhost:10101/metrics` respond?
- Attempt to restart praefect service: `sudo gitlab-ctl restart praefect`

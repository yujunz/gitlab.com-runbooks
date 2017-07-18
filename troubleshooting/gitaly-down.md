# Gitaly is down

## First and foremost

*Don't Panic*

## Symptoms

* Message in prometheus-alerts _Gitaly is down on [hostname]_

## 1. Ensure that the file server is running

- Is the NFS file server running and accessible? Can you access it via a shell session?

## 2. Check the Gitaly Logs

- Check Sentry for unusual errors: https://sentry.gitlap.com/gitlab/gitaly-production/
- Check Kibana for increased error rates: https://log.gitlap.com/goto/5347dee91b984026567bfa48f30c38fb
- Check the Gitaly service logs on the affected host

## 3. Ensure that the Gitaly server process is running

- Can you see the process in `ps aux | grep gitaly`?
- Is the prometheus port responding: Does `curl https://localhost:9236/metrics` respond?
- Attempt to restart gitaly service. TODO: preferred method for starting a GitLab service in production.

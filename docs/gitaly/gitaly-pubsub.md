# Gitaly PubSub Rate is low

## Symptoms

* Message in alerts _Gitaly PubSub send operation is low_

## 1. Ensure that logging is configured correctly
## 2. Check the Gitaly Logs
## 3. Ensure that the Gitaly server process is running
- Can you see the process in `ps aux | grep gitaly`?
- Is the prometheus port responding: Does `curl https://localhost:9236/metrics` respond?
- Attempt to restart gitaly service: `sudo gitlab-ctl restart gitaly`

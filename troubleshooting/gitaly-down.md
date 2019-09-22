# Gitaly is down

## First and foremost

*Don't Panic*

## Symptoms

* Message in prometheus-alerts _Gitaly is down on [hostname]_

## 1. Ensure that the file server is running

- Is the NFS file server running and accessible? Can you access it via a shell session?

### If the server rebooted
 - try to find the reason for the reboot.
   - have a look at the stackdriver GCE VM instance logs for cloudaudit system events and serial console output.
 - check for zero size object files
   - necessary until [this](https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/7851) get's fixed
   - else there will be errors with pushing, cloning, web ui...

```
# in a screen session (will take a while)
cd /var/opt/gitlab/git-data/repositories/@hashed
ionice -n 5 find . -regextype sed -regex ".*/objects/.*" -size 0 -mtime +1 > /var/tmp/zerofiles.txt

# remove all found zero size object files.
# customers need to re-push to fix those files.

# if customers still report issues,
# check each affected repo for consistency:
sudo -u git
cd <repo>
git fsck

# for each found invalid sha1 pointer,
# if it looks like an important branch (like master), set it to a previous commit.
# finding previous commit on console:
# project.events.where(action: Event::PUSHED).last.push_event_payload.commit_from
#
# Else:
git update-ref -d <invalid_ref_found_by_git_fsck>

# at the end
git fsck --full

# let the customer re-push again.
```


## 2. Check the Gitaly Logs

- Check [Sentry](https://sentry.gitlab.net/gitlab/gitaly-production/) for unusual errors
- Check [Kibana](https://log.gitlab.net/goto/4f0bd7f08b264e7de970bb0cc9530f9d) for increased error rates
- Check the Gitaly service logs on the affected host
  - grep for `SIGSEGV` or `SIGILL` in `/var/log/gitlab/gitaly/`
- Check [Grafana dashboards](https://dashboards.gitlab.net/dashboard/db/gitaly-nfs-metrics-per-host?orgId=1) to check for a cause of this outage

## 3. Ensure that the Gitaly server process is running

- Can you see the process in `ps aux | grep gitaly`?
- Is the prometheus port responding: Does `curl https://localhost:9236/metrics` respond?
- Attempt to restart gitaly service: `sudo gitlab-ctl restart gitaly`

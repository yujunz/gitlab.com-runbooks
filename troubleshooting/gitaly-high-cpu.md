# Gitaly CPU too high on a file server

## Symptoms

* Load spike on the NFS servers, high I/O load.
* Message in prometheus-alerts _Gitaly: High CPU usage on host_

## Possible checks

- Open the [**Gitaly NFS Metrics per Host** dashboard](https://dashboards.gitlab.net/dashboard/db/gitaly-nfs-metrics-per-host?refresh=30s&orgId=1&var-fqdn=nfs-file-08.stor.gitlab.com&from=now-1h&to=now) making sure to select the correct host,
  and check the metrics
- Log into the NFS server through a shell
- Use `uptime` and `iotop` to check the current load values on the box
- Use top to check whether or not Gitaly is using very high levels of CPU
- As a last resort, restart the gitaly service: `sudo gitlab-ctl restart gitaly`. **This has service impact.**

### Long running or orphan `git` processes

If a user or CI is overloading an NFS server with multiple intensive concurrent git operations, 
it's better to kill the processes than have the whole server -- or even just the Gitaly process -- fail.

Almost all git processes are safe to kill without the risk of corrupting the repository.

#### Selecting the best `git` processes to terminate

Prioritise the termination of `git` processes in the following order:

* **Orphaned Git Processes**: `git` chains together deep process heirachies in order to perform some tasks. If the parent has died, the child may continue to run. 
  Gitaly uses process groups to manage these, but orphaned git child processes can always be terminated immediately.
    * Check for git orphans: `pgrep -a -u git -P 1`. If you have `pstree` use ```for i in `pgrep -P 1 -u git git`; do pstree -l -a -p $i; done``` 
    * When terminating orphan processes, ensure that any new orphans are also terminated by repeating the process several times.
    
* **Long Running GC and Repack Processes**: 
  * `pgrep -f -a -u git -P 1 'gc|repack'`
  * These are low-priority tasks but can be resource intensive. Sometimes multiple GCs and repacks can occur on the same repo concurrently, which is a huge waste of resources as they will contend and only
    the first to complete will persist it's results.

* **Other Long Running Git Processes**:
  * ``` pgrep -u git git | xargs ps -o pcpu,pid,ppid,args,etime --sort -etime -p``` 
  * This may also help: ```ps -u git -o pcpu,pid,ppid,args,etime --sort -etime --forest```
  * Show the Gitaly process hierarchy, ordered by longest running processes first ```ps -u git -fwwwwH  --sort=-start```
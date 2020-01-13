# HAPrpoxy Alert Troubleshooting

## Reason
* Errors are being reported by HAProxy, this could be a spike in 5xx errors,
  server connection errors, or backends reporting unhealthy.

## Prechecks
* Examine the health of all backends and the HAProxy dashboard
    * HAProxy - https://dashboards.gitlab.net/d/ZOOh_aNik/haproxy
    * HAProxy Backend Status - https://dashboards.gitlab.net/d/7Zq1euZmz/haproxy-status?orgId=1
* Is the alert specific to canary servers or the canary backend? Check canaries
  to ensure they are reporting OK. If this is the cause you should immediately change the weight of canary traffic.
    * Canary dashboard - https://dashboards.gitlab.net/d/llfd4b2ik/canary
    * To disable canary traffic see the [canary chatops documentation](https://gitlab.com/gitlab-org/release/docs/blob/master/general/deploy/canary.md#canary-chatops)

## Resolution
* If there is a single backend server alerting, check to see if the node is healthy on
  the host status dashboard. It is possible in some cases, most notably the git
  server where it is possible to reject connections even though the server is
  reporting healthy.
    * on the server see the health of the service `gitlab-ctl status`
    * for git servers check the status of ssh `service sshd_git status`
* HAProxy logs are not currently being sent to ELK because of capacity issues.
  These logs can be viewed in stackdriver. Production logs can be viewed using this [direct link](https://console.cloud.google.com/logs/viewer?project=gitlab-production&authuser=1&minLogLevel=0&expandAll=false&timestamp=2018-10-08T07:43:05.667000000Z&customFacets=&limitCustomFacetWidth=true&dateRangeStart=2018-10-08T06:43:05.918Z&dateRangeEnd=2018-10-08T07:43:05.918Z&interval=PT1H&resource=gce_instance&scrollTimestamp=2018-10-08T07:42:43.008000000Z&logName=projects%2Fgitlab-production%2Flogs%2Fhaproxy)
* If the errors are from web-pages backends, consider possible intentional abuse or accidental DoS from specific IPs or for specific domains in [Pages](https://us-central1-gitlab-infra-automation-stg.cloudfunctions.net/ui/services/pages)
  * Client IPs can be identified by volume from the current haproxy logs on the haproxy nodes with `sudo grep -v check_http /var/log/haproxy.log | awk '{print $6}' | cut -d: -f1|sort|uniq -c |sort -n|tail`.  Identifying problematic levels is not set in stone; hopefully if there is one or two (or a subnet), they will stand out.  Consider removing the 'tail' or making it 'tail -100' etc, to get more context.
    * To block: In https://gitlab.com/gitlab-com/security-tools/front-end-security/ edit deny-403-ips.lst.  commit, push, MR, ensure it has pull mirrored to ops.gitlab.net, then run chef on the pages haproxy nodes to deploy.  This will block that IP across *all* frontend (pages, web, api etc), so be sure you want to do this.
  * Problem sites/projects/domains can be identified with the `Gitlab-Pages activity` dashboard on kibana - https://log.gitlab.net/app/kibana#/dashboard/AW6GlNKPqthdGjPJ2HqH
    * To block: In https://gitlab.com/gitlab-com/security-tools/front-end-security/ edit deny-403-ips.lst.  commit, push, MR, ensure it has pull mirrored to ops.gitlab.net, then run chef on the pages haproxy nodes to deploy.  This will block only the named domain (exact match) in pages, preventing the request ever making it to the web-pages servers.  This is very low-risk

## Extraneous processes

HAProxy forks on reload and old processes will continue to service requests, for
long-lived ssh connections we use the `hard-stop-after` [configuration parameter](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/6156b09464c18bc5b584f5bf5e363fd50ded4af7/roles/gprd-base-lb-fe.json#L6-10)
to prevent processes from lingering more than 5 minutes.

In https://gitlab.com/gitlab-com/gl-infra/delivery/issues/588 we have observed that processes remain for longer than this interval, this may require manual intervention:

* Display the process tree for haproxy, for example here it shows two processes where we expect one:

```
# pstree -pals $(pgrep -u root -f /usr/sbin/haproxy)
systemd,1 --system --deserialize 36
  └─haproxy,28214 -Ws -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -sf 1827
      ├─haproxy,1827 -Ws -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -sf 1639
      └─haproxy,2002 -Ws -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -sf
```

* Show the elapsed time of the haproxy processes:

```
# for p in $(pgrep -u haproxy -f haproxy); do ps -o user,pid,etimes,command $p; done
USER       PID ELAPSED COMMAND
haproxy   1827   99999 /usr/sbin/haproxy -Ws -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -sf 1639
USER       PID ELAPSED COMMAND
haproxy   2002      20 /usr/sbin/haproxy -Ws -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -sf 1827

```

* Kill the process with the longer elapsed time:

```
# kill -TERM 1827
```

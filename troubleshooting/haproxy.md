# HAPrpoxy Alert Troubleshooting

## First and foremost

*Don't Panic*

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
    * Canary howto - https://gitlab.com/gitlab-com/runbooks/blob/master/howto/canary.md

## Resolution
* If there is a single backend server alerting, check to see if the node is healthy on
  the host status dashboard. It is possible in some cases, most notably the git
  server where it is possible to reject connections even though the server is
  reporting healthy.
    * on the server see the health of the service `gitlab-ctl status`
    * for git servers check the status of ssh `service sshd_git status`
* HAProxy logs are not currently being sent to ELK because of capacity issues.
  These logs can be viewed in stackdriver. Production logs can be viewed using this [direct link](https://console.cloud.google.com/logs/viewer?project=gitlab-production&authuser=1&minLogLevel=0&expandAll=false&timestamp=2018-10-08T07:43:05.667000000Z&customFacets=&limitCustomFacetWidth=true&dateRangeStart=2018-10-08T06:43:05.918Z&dateRangeEnd=2018-10-08T07:43:05.918Z&interval=PT1H&resource=gce_instance&scrollTimestamp=2018-10-08T07:42:43.008000000Z&logName=projects%2Fgitlab-production%2Flogs%2Fhaproxy)

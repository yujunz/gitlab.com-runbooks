## Reason

Kibana service is not running.

## Possible checks

1. Open log.gitlap.com and login - you can see 502 error
1. SSH to the `log.gitlap.com` and if in results of `sudo service kibana status` service should be `active (running)`. Otherwise it is down.

## Fix

1. SSH to the `log.gitlap.com`.
2. Restart service with the `sudo service kibana restart`.
3. Check service with the `sudo service kibana status`.

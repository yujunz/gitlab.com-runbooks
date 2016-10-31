## Reason

It is possible that docker not correctly reloaded/restarted between chef runs.

## Possible checks

1. Try to open https://runners-cache-1.gitlab.com:1443/v2, if you receive 502 error, then registry is down
1. Login to `runners-cache-1.gitlab.com` and if `sudo docker ps | grep registry` has no output, then registry is down 

## Fix

1. Login to `runners-cache-1.gitlab.com`
1. Restart docker image for cache with `sudo docker restart registry`

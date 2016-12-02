## Reason

It is possible that docker not correctly reloaded/restarted between chef runs.

## Possible checks

1. In the case of `runners-cache-1.gitlab.com`. Replace hostname in the following text with your hostname if the case.
1. Try to open https://runners-cache-1.gitlab.com/minio/login, if you receive 502 error, then cache is down.
1. If you are not receiving anything, then check nginx, by login to `runners-cache-1.gitlab.com` and `sudo service nginx status` and if it is `Active: inactive` state, then start it by `sudo service nginx start`.
1. Login to `runners-cache-1.gitlab.com` and if `sudo docker ps | grep minio` has no output, then cache is down. 

## Fix

1. Login to `runners-cache-1.gitlab.com`
2. Restart docker image for cache with `sudo docker restart minio_minio`

## Reason

It is possible that docker hasn't correctly reloaded/restarted between chef runs or a container is stuck.

## Background

There are several services required to operate the runners cache.

The blackbox prober instances look like this:
* Docker registry: `runners-cache-X.gitlab.com:5000/v2`
* Minio object storage: `runners-cache-X.gitlab.com:9000/minio/login`

Nginx acts as a proxy for the registry, which is backed by minio.

Both registry and minio run as containers: run `sudo docker ps -a` to check out their status.

## Possible checks

We're assuming the hostname is `runners-cache-1.gitlab.com` for the rest of this page.

1. Log into the runners-cache instance that is alerting.
1. Try to open https://runners-cache-1.gitlab.com/minio/login. If you receive 502 error, then cache is down. Bear in mind it could be down even if you get the login page.
1. If you are not receiving anything, then check nginx with `sudo service nginx status`. If the state is `Active: inactive` then start it by `sudo service nginx start`.
1. Check that minio is up with `sudo docker ps | grep minio`.
1. Check if the registry container is receiving requests with `sudo docker logs --tail 1 registry`. If it's more than 10 minutes then you need to recycle the container.

## Fix

Usually you need to restart the containers:

1. Login to `runners-cache-1.gitlab.com`
1. Stop all the containers, running and not: `sudo docker rm -f minio registry`
1. Run `sudo chef-client` to restart them.
1. Check that they started correctly by inspecting the logs.

# Alerts that runners cache or registry is down

## Symptoms

Users my see errors during cache download or upload in pipelines.
Usually it is 502 alerts for. Reason is docker sometimes not correctly reloaded
between chef runs.

## Possible checks

1. Try following urls in browser

- http://runners-cache-1.gitlab.com/minio/login
- http://runners-cache-1.gitlab.com:1443/v2

If cache gives HTTP code 502, then runners cache is down, if second one gives 502, then runners registry is down.

1. Login to `runners-cache-1.gitlab.com`

Run `sudo docker ps`. There should be two docker images running. If there is only one or none, then corresponding service(s) is/are down.

Output when both services are up
```
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES
d04ef1fed99a        fbb189b55b81        "go-wrapper run serve"   13 days ago         Up 3 hours          0.0.0.0:9000->9000/tcp   minio_minio
1d80720a31bc        541a6732eadb        "/entrypoint.sh /etc/"   13 days ago         Up 3 hours          0.0.0.0:5000->5000/tcp   registry
```

## Resolution

1. Restarting runners cache

On `runners-cache-1.gitlab.com` run following

```
sudo docker restart minio_minio
```

1. Restarting runners registry

On `runners-cache-1.gitlab.com` run following

```
sudo docker restart registry
```

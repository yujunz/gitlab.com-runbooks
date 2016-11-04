## Reason

It is possible that docker not correctly reloaded/restarted between chef runs.

## Possible checks

1. Try to open https://runners-cache-1.gitlab.com:1443/v2, if you receive 502 error, then registry is down
1. Login to `runners-cache-1.gitlab.com` and if `sudo docker ps | grep registry` has no output, then registry is down 
1. Try to pull an image from the cache. The easiest way is to login to an existing shared runner:
 
   ```sh
   ssh shared-runners-manager-1.gitlab.com
   sudo su -
   docker-machine ls | head
   ```
  
   For example, you should then see a list:
   
   ```
   root@shared-runners-manager-1:~# docker-machine ls | grep Running | head
   runner-8a2f473d-machine-1478160175-c4b230b1-digital-ocean-4gb   -        digitalocean   Running    tcp://162.243.122.64:2376           v1.11.2   
   runner-8a2f473d-machine-1478199487-7fa9607f-digital-ocean-4gb   -        digitalocean   Running    tcp://107.170.60.84:2376            v1.11.2   
   runner-8a2f473d-machine-1478199826-af7be2c3-digital-ocean-4gb   -        digitalocean   Running    tcp://162.243.205.73:2376           v1.11.2   
   runner-8a2f473d-machine-1478199870-4ab33bab-digital-ocean-4gb   -        digitalocean   Running    tcp://162.243.116.25:2376           v1.11.2   
   runner-8a2f473d-machine-1478199870-5850095c-digital-ocean-4gb   -        digitalocean   Running    tcp://107.170.8.155:2376            v1.11.2   
   runner-8a2f473d-machine-1478199870-aad92145-digital-ocean-4gb   -        digitalocean   Running    tcp://107.170.19.82:2376            v1.11.2   
   runner-8a2f473d-machine-1478199979-858042ff-digital-ocean-4gb   -        digitalocean   Running    tcp://107.170.29.171:2376           v1.11.2   
   runner-8a2f473d-machine-1478199979-3744497f-digital-ocean-4gb   -        digitalocean   Running    tcp://107.170.70.240:2376           v1.11.2   
   runner-8a2f473d-machine-1478199994-f54716a9-digital-ocean-4gb   -        digitalocean   Running    tcp://162.243.20.163:2376           v1.11.2   
   runner-8a2f473d-machine-1478200003-5a3c359d-digital-ocean-4gb   -        digitalocean   Running    tcp://107.170.30.60:2376            v1.11.2   
   ```
   
   You can then login via `docker-machine ssh` and pull an image. If everything is working, you should see something like:
   
   ```sh
   root@shared-runners-manager-1:~# docker-machine ssh runner-8a2f473d-machine-1478160175-c4b230b1-digital-ocean-4gb 
   Last login: Thu Nov  3 08:03:36 UTC 2016 from 192.241.182.179 on ssh
   CoreOS stable (1185.3.0)
   2.1: Pulling from library/ruby
   43c265008fae: Already exists 
   af36d2c7a148: Downloading [===================================>               ] 13.21 MB/18.53 MB
   143e9d501644: Downloading [=========>                                         ] 8.178 MB/42.5 MB
   df720fc8e4f1: Downloading [========>                                          ] 21.57 MB/129.8 MB
   3da50f5b595a: Waiting 
   4ff3dfece345: Waiting 
   2a8e581336d3: Waiting 
   7cdf27133962: Waiting 
   ```

## Fix

1. Login to `runners-cache-1.gitlab.com`
1. Restart docker image for cache with `sudo docker restart registry`

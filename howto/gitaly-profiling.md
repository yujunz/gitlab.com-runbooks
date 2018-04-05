# Gitaly profiling

## First and foremost

* *Don't Panic*


## 1. Download the profiles

These commands can be executed either from the server itself, or from any VPN-connected
computer. To easily hand of the files it's suggested to run it from a VPN-connected computer.  

* Replace `<SERVER_IP>` with the IP for the Gitaly server you want to profile.
* Replace `<PROM_PORT>` with the prometheus port configured for Gitaly.
* IP and Port can be found [here](https://prometheus.gitlab.com/targets#job-gitaly-production)


- `curl -o cpu.bin http://<SERVER_IP>:<PROM_PORT>/debug/pprof/profile`
  - This fetches 30 seconds of CPU profiling for flame graphs.
- `curl -o trace.bin http://<SERVER_IP>:<PROM_PORT>>/debug/pprof/trace?seconds=5`
  - This fetches 5 seconds of execution trace.
- `curl -o heap.bin http://<SERVER_IP>:<PROM_PORT>>/debug/pprof/heap`
  - This fetches a heap profile to profile memory usage.

## 2. Hand them off

To the Gitaly Team attached to an [issue](https://gitlab.com/gitlab-org/gitaly/issues/new).
Remember to make it confidential.

# Gitaly profiling

## First and foremost

* *Don't Panic*


## 1. Download the profiles

These commands can be executed either from the server itself or your own computer.

* Replace `<SERVER_IP>` with the IP for the Gitaly server you want to profile.
* Replace `<PROM_PORT>` with the prometheus port configured for Gitaly.
* IP and Port can be found [here](https://prometheus.gitlab.com/targets#job-gitaly-production)


- `curl -o cpu.bin http://<SERVER_IP>:<PROM_PORT>/debug/pprof/profile`
  - This fetches 30 seconds of CPU profiling for flame graphs.
- `curl -o trace.bin http://<SERVER_IP>:<PROM_PORT>>/debug/pprof/trace?seconds=5`
  - This fetches 5 seconds of execution trace.
- `curl -o heap.bin http://<SERVER_IP>:<PROM_PORT>>/debug/pprof/heap`
  - This fetches a heap profile to profile memory usage.
- `curl -o goroutines.txt http://<SERVER_IP>:<PROM_PORT>>/debug/pprof/goroutine?debug=2`
  - This fetches a list of running goroutines.

## 2. Hand them off

To the Gitaly Team attached to an [issue](https://gitlab.com/gitlab-org/gitaly/issues/new).
Remember to make it confidential.

## 3. Analyze profiling data

Make sure you have the go SDK installed.

### Finding where CPU time is spend

* Run `go tool pprof cpu.bin` to enter interactive mode.
  * use `top 30` to show the top 30 methods for CPU consumption
  * In most cases it's better to sort by cumulative CPU consumption: `top 30 -cum`

* Or use it non-interactively:
  * `go tool pprof -top -cum cpu.bin`

* To look into one of the listed methods to see CPU usage for each line of code:
  * `go tool pprof -source_path </path/to/go_src> -list <methodname_regexp> cpu.bin`

* To get a graphical tree representation of CPU consumption:
  * `go tool pprof -web cpu.bin`

### Finding where memory is allocated

Same as with CPU profiling above, but using the `heap.bin` file instead of `cpu.bin`.
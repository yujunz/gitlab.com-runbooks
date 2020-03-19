# Gitaly profiling

## First and foremost

* *Don't Panic*


## 1. Download the profiles

A convenient way is to use ssh port forwarding to download the profiles
directly to your own workstation. The actual Gitaly port (`9236`) can be found
[here](https://prometheus.gprd.gitlab.net/targets#job-gitaly). We are
forwarding this to our local port `6060` as this is the standard port for go
pprof endpoints.

```
ssh -N -L 6060:localhost:9236 file-03-stor-gprd.c.gitlab-production.internal
```

```
# fetch 30 seconds of CPU profiling
curl -o cpu.bin http://localhost:6060/debug/pprof/profile

# fetch 5 seconds of execution trace (this will have a performance impact)
curl -o trace.bin http://localhost:6060/debug/pprof/trace?seconds=5`

# fetch a heap profile to profile memory usage
curl -o heap.bin http://localhost:6060/debug/pprof/heap

# fetch a list of running goroutines
curl -o goroutines.txt http://localhost:6060/debug/pprof/goroutine?debug=2
```

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

* Or **get all the goodness in one nice web interface** (pprof will listen on localhost:8080):
  * `go tool pprof -http localhost:8080 cpu.bin`

### Finding where memory is allocated

Same as with CPU profiling above, but using the `heap.bin` file instead of `cpu.bin`.
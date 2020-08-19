# Node CPU alerts

## HighCPU

This indicates there may not be enough CPU on the node in order to operate.

### Profiling

If there is an increase in CPU utilization on a single host, you may want to
perform CPU profiling or look at profiles from our continuous profiling in
[Google Cloud
Profiler](https://console.cloud.google.com/profiler?project=gitlab-production).

For ad-hoc profiling, it is also possible to invoke the profiler on a process
directly.

* For Go processes, you can profile via [pprof](https://golang.org/pkg/runtime/pprof/).
* For Ruby processes, you can profile see: [ruby-profiling.md](Ruby profiling).
* For C processes and kernel profiling, you can use [perf](http://www.brendangregg.com/perf.html), see also [Redis - CPU profiling](../redis/redis.md).

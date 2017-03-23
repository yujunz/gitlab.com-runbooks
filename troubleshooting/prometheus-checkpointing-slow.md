# Prometheus Checkpointing Slow

## Symptoms

Prometheus is taking a long time to checkpoint its unpersisted in-memory
state to its checkpoint file. Normal times should be <5 minutes, but
specifically not more than 200µs per unpersisted chunk.

## Possible checks

Check how the value of `prometheus_local_storage_checkpoint_duration_seconds`
developed over time. Perhaps it increased recently? Did the number of time
series increase recently, which could have led to more chunks in the checkpoint?
Graph `prometheus_local_storage_memory_series`.

In general, any kind of load can contribute to longer checkpoint times,
especially IO load.

## Resolution

Reduce the load on the Prometheus server by either reducing the number of
handled time series, the number of rules, rates of queries, or other causes
of load.
# Thanos Compact

Thanos compact failures are almost always discoverable in the logs.

## Common problems

* OOMs, check for crashes in the logs or non-zero `node_vmstat_oom_kill` .
* Storage, Large compactions may trigger a full filesystem. Restart of `thanos-compact` will clear the compaction cache.

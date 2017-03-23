# Prometheus Rule Evaluation Slow

## Symptoms

Rule-based metrics are appearing with a lag or not at all anymore because
Prometheus's rule evaluator takes a long time to complete a cycle.

## Possible checks

Check how the expression `prometheus_evaluator_duration_seconds{quantile="0.9",job=~"prometheus.*"}`
developed over time. Did it recently increase by a lot? Perhaps the rule
evaluation got slower due to more time series. Check for a recent increase
in time series: `prometheus_local_storage_memory_series`.

Perhaps the Prometheus server is overloaded by other things or in general,
there might be too many expensive rules configured.

## Resolution

Reduce the load on the Prometheus server by either reducing the number of
handled time series, the number of rules, rates of queries, or other causes
of load.
# Prometheus Rule Evaluation Slow

## Symptoms

Rule evaluations are executed in sequence on a per rule file/group basis.
Slow server performance or expensive rules can cause them to take too long to complete.

## Possible checks

Check how the expression `prometheus_evaluator_duration_seconds{quantile="0.9",job=~"prometheus.*"}`
developed over time. Did it recently increase by a lot? Perhaps the rule
evaluation got slower due to more time series. Check for a recent increase
in time series: `prometheus_local_storage_memory_series`.

Perhaps the Prometheus server is overloaded by other things or in general, possibly not enough memory or IO resources.

The rules are expensive, and look over a large number of metrics and/or samples.

## Resolution

Reduce the load on the Prometheus server by:
* Reduce the number of executed rules in a rule group so that they can be executed in parallel.
* Reduce the number of series, or amount of smaples required to evaluate a rule.
* Increase the memory or other node resources to speed up evaluations.

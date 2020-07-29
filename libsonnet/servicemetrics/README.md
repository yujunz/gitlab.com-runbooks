# ServiceMetrics

This module contains code to generate key service metric indicators
at different burn rates.

The metrics are:

* Apdex (for latency)
* Requests (per second)
* Error Rates (per second)
* Saturation and Utilization metrics (as a ratio)

This module should not generate metrics for GitLab.com specifically. Keep
GitLab.com specific configuration in the metrics catalog itself when possible.

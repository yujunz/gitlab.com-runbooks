# Service Apdex

The apdex score for a service is a measure of relative performance for a service.

Our apdex scoring is loosely based on NewRelic's apdex scoring: https://docs.newrelic.com/docs/apm/new-relic-apm/apdex/apdex-measure-user-satisfaction

For a given service, we define two latency values:

* **Satisfied**: this is the target latency for incoming requests to this service.
* **Tolerated**: this is a acceptable, tolerated latency.

The apdex score for a service is measured as:

```
(satisfied requests) + (tolerated requests)/2
---------------------------------------------
         total number of requests
```

Note, importantly that requests are only considered satisfactory and torelarable if they're successful and do not fail.
This implies that the apdex score includes a error-rate factor - as more request fail, the apdex score will tend to zero,
no matter the latency of the failures.

## Determining availability

The apdex score for a service depends on the service exporting Prometheus latency histograms. For this reason, we currently to do have
apdex scores for postgres or redis.

Additionally, for some services, such as Gitaly, the apdex is based on a subset of all requests. For example, in Gitaly, the GC
request latency is a function of repository size and time since last GC. In normal operation, this call may take up to 30 minutes.
Including this in the apdex score is unhelpful and does not provide insight into the state of the service, so it is excluded from
the metric.

## Service Availablity Definitions

The definitions of service availability are defined in https://gitlab.com/gitlab-com/runbooks/blob/master/recordings/service_apdex.yml

# Service Availability

At GitLab, we define the availability of a service as a ratio of: `the number of instances of a service reporting as healthy` / `the expecting number if instances of that service`.

It is a measure of the health-check status of a service.

For example, if we expect there to be 20 `unicorn` processes in the `web` fleet and 15 are available and reporting as healthy, then the availablity of the `unicorn` _component_ of the `web` _service_ is 0.75, or 75%.

## Determining availability

This is usually done in one of three ways:

1. For services which host their own Prometheus metrics endpoint internally, we usually rely on the status of the `up` metric for the service. This endpoint is (by design) a useful health-check onto a process. In order to have `up{..}=1` the service needs to be running, listening on the port and correctly responding to incoming requests.

1. For services that use sidecar Prometheus exporter processes, we rely on metrics they export. For example, in the case of Redis, we rely on the `redis_up` metric exported by that process.

1. For services that provide neither a Prometheus exporter sidecar, nor an internal scrape endpoint, we may rely on an external service health check, for example, for services HAProxy metrics can provide an insight into the status of the service. This is the least desirable approach.

## Service Availablity Definitions

The definitions of service availability are defined in https://gitlab.com/gitlab-com/runbooks/blob/master/rules/service_availability.yml

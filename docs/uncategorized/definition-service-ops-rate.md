# Service Operation Rate

The operation rate of a service is a measure of how many requests the service is having to handle per second.

Note the operation rate of a service is the sum of the operation rates of each component within that service, so the
metric should be considered relative to the historical value, rather than an absolute number.

This is probably best explained with an example: The `web` service is comprised of `unicorn`, `workhorse` and `nginx` components.

A single user request may create one request to `nginx`, one request to `workhorse` and one request to `unicorn`. The operation rate, will
therefore reflect three requests, rather than one.

Since each component is reporting metrics separately, it's easier to handle things in this manner, than attempting to correlate multiple
sources to a single request.

## Service Availability Definitions

The definitions of service availability are defined in https://gitlab.com/gitlab-com/runbooks/blob/master/rules/service_ops_rate.yml

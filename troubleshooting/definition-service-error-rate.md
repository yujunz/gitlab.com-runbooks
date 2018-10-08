# Service Error Rate

The error rate for a service is a measure of how many errors that service is generating per second.

Note the error rate of a service is the sum of the error rates of each component within that service, so the
metric should be considered relative to the historical value, rather than an absolute number.

This is probably best explained with an example: The `web` service is comprised of `unicorn`, `workhorse` and `nginx` components.

A single error in the `unicorn` component may bubble up and may be reported as three `500` errors - one in `unicorn`, one in `workhorse` and one in `nginx`. The
error rate of the service is the sum of these values, so would report 3 for a single error bubbling up through the layers.

## Service Availablity Definitions

The definitions of service availability are defined in https://gitlab.com/gitlab-com/runbooks/blob/master/recordings/service_error_rate.yml

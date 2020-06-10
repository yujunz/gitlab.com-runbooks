# CloudFlare Troubleshooting

## Symptoms

There are certain conditions which indicate a CloudFlare-specific problem.
For example, if there are elevated CloudFlare errors but not production errors,
the problem must be inside CloudFlare.

Here is a list of potential sources of errors

### Static objects cache

[Static objects cache][static-objects-cache-howto] for production is deployed
as a CloudFlare worker in the gitlab.net zone. If the alert you got indicated
the gitlab.net zone, and requests to `/raw/` or `/-/archive` endpoints are
failing then it's worth checking how the worker is operating. See its
[runbook][static-objects-cache-troubleshooting] for troubleshooting information.

[static-objects-cache-howto]: ../web/static-repository-objects-caching.md
[static-objects-cache-troubleshooting]: ../web/static-objects-caching.md

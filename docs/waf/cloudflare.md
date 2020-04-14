# CloudFlare

## Logs

Each CloudFlare zone pushes logs to a Google Cloud Storage (GCS) bucket with the name of
`gitlab-<environment>-cloudflare-logpush`. This operation happens every 5 minutes
so the logs don't give an immediate overview of what's currently happening.

At the moment we don't have a way of analyzing them in a controlled manner such as BigQuery or Kibana.

We have however a script, which allows us to access a NDJSON stream of logs. This script can be found in `scripts/cloudflare_logs.sh`

The usage of the script should be limited to a console host because of traffic cost. It will need to read the whole logs for the provided timeframe.

Example:

To get the last 30 minutes of logs up until 2020-04-14T00:00 UTC as a stream, use
```bash
./cloudflare_logs.sh -e gprd -d 2020-04-14T00:00 -t http -b 30
```
you can then `grep` on that to narrow it down. The use of `jq` on an unfiltered stream is not recommended, as that significantly increases processing time.

Beware, that this process will take long for large timespans.

Full example to search for logs of a given project which have a 429 response code:
`./cloudflare_logs.sh -e gprd -d 2020-04-14T00:00 -t http -b 2880 | grep 'api/v4/projects/<PROJECT_ID>' | jq 'select(.EdgeResponseStatus == 429)'`

Note: Due to the way logs are shipped into GCS, there might be a delay of up to 10 minutes for logs to be available.

## Symptoms

There are certain conditions which indicate a CloudFlare-specific problem.
For example, if there are elevated CloudFlare errors but not production errors, the problem must be inside CloudFlare.

Here is a list of potential sources of errors

### Static objects cache

[Static objects cache][static-objects-cache-howto] for production is deployed as a CloudFlare worker in
the gitlab.net zone. If the alert you got indicated the gitlab.net zone, and requests to `/raw/` or `/-/archive`
endpoints are failing then it's worth checking how the worker is operating. See its [runbook][static-objects-cache-troubleshooting]
for troubleshooting information.

[static-objects-cache-howto]: ../web/static-repository-objects-caching.md
[static-objects-cache-troubleshooting]: ../web/static-objects-caching.md

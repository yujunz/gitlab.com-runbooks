# Prometheus Not Ingesting

## Symptoms

Prometheus is not ingesting any new samples, so new data points will not
appear in queries, and alerts will have no data to work on.

## Possible checks

To check whether this is a misconfiguration (no targets configured or
discovered), check the `/targets` page on the Prometheus server to verify
that there are discovered targets.

To check whether there is another problem, login to the machine and check
the Prometheus logs and general Prometheus health metrics.

## Resolution

Fix the targets misconfiguration or fix whatever other problem was indicated
in the logs.
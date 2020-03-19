# Prometheus Invalid Configuration File

## Symptoms

Prometheus is ingesting samples for the same series with duplicate timestamps,
but different values.

## Possible checks

Check whether there are any two targets that got relabeled into the same labelset.
Are there any targets that are explicitly using client-side timestamps in their
`/metrics` incorrectly?

## Resolution

Fix the erroneous relabling rules or the targets that produce wrongly timestamped
data.
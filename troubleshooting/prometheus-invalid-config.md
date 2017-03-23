# Prometheus Invalid Configuration File

## Symptoms

Prometheus cannot read its configuration file and will thus keep on using a
previously loaded configuration. On restart, Prometheus will crash due to
not being able to load its config.

## Possible checks

Log in to the Prometheus server and check the logs to see what exact
configuration error is being reported.

## Resolution

Fix the reported configuration error.
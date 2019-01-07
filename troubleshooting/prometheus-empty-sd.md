# Prometheus Empty Service Discovery

## Symptoms

Prometheus has one or more jobs with empty target lists.

## Possible checks

Check to see if there are problems with the service discovery method.

For `file_sd_configs`, check to see if there is a problem with Chef generating the target file.

There may also be jobs that are obsolete and need to be removed.

## Resolution

Fix the SD method or remove the job from the config.

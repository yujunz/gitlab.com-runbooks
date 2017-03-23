# Prometheus Storage Inconsistent

## Symptoms

Prometheus has encountered an inconsistency in its storage while reading/writing
from/to it. Some series may now be inaccessible or have problems.

## Possible checks

Log in to the Prometheus server and check the logs to see if there is any specific
error pointed out. Did the server crash recently?

## Resolution

Restart Prometheus gracefully to trigger a recovery run.
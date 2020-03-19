# Prometheus WAL Corruptions

## Symptoms

Prometheus WAL detected corruption.

This can occur in the case of broken or full filesystems.

## Possible checks

* Check the Prometheus logs for indications of problems.
* Check the kernel log for filesystem errors.
* Check the disk space usage.

## Resolution

There is not much to be done here, since corruptions can't be repaired and are automatically cleaned up by the WAL repair at startup.

* Validate filesystem is OK and not full.
* Restart Prometheus.

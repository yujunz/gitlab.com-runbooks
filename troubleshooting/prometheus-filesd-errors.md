# Prometheus FileSD read errors

## Symptoms

The `rate(prometheus_sd_file_read_errors_total[5m])` expression is showing
a higher error rate and new targets are not picked up from the SD files.

## Possible checks

1. Login to the server and study the Prometheus logs.
1. Look for lines containing "Error reading file".

The specific error message should say why the file couldn't be read.

## Resolution

If the file couldn't be read because it is a malformed target file, fix the file.

If the file couldn't be read because there was a permissions error, fix the file permissions.

If the file couldn't be read because there was a disk I/O error, fix / move the machine.
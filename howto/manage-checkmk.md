# Managing CheckMK

## Reload host metrics

To fix some of the errors that may be blocked in CheckMK (_UNKNOWN - Database not found_ for ex)
it may be necessary to reload the host configuration:

* ssh into the checkmk server and run the following commands
  * `sudo su - gitlab`
  * `cmk -II $hostname && cmk -O`

This is also necessary when we add new metrics to a host. These metrics will not show until the
host is reloaded.

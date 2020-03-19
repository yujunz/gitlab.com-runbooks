# Prometheus Notifications Backlog

## Symptoms

Prometheus is having trouble working off its queue of notifications to send
to Alertmanager. Alert notifications may get delivered late or not at all.

## Possible checks

See how `prometheus_notifications_queue_length` developed
over time. Log in to the machine and check the Prometheus logs to see if
Prometheus is encountering any errors while sending alerts to Alertmanager.
Check that Alertmanager is reachable and not overloaded.

## Resolution

Depending on the above checks, either address the errors that are logged
by Prometheus or ensure that Alertmanager is healthy again.
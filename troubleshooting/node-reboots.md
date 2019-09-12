# Node Reboots

Search tags: reboot, restart, instance, node, VM, machine

## Discovering GCE Casualties

Sometimes GCE has issues themselves and force node restarts.  We can find these
to validate GCE is the root cause by using the following search in stackdriver:

```
resource.type="gce_instance"
protoPayload.serviceName="compute.googleapis.com"
protoPayload.methodName="compute.instances.hostError"
protoPayload.methodName="automaticRestart"
```

What you'll notice with the above search is that GCE will notice an error of
some sort on the physical node, which causes the `hostError`, and normally
shortly after this within 5 hundredths of a second, you'll see the `automaticRestart`

If you don't see the above, there may not be an issue from the GCE side of
things and at this point, you should start troubleshooting potential problems,
such as kernel panics, user induced reboots, or instance deletions.

## Instance Deletions

Node deletions can be found by using the below on your search query:

```
protoPayload.methodName="delete"
```

Normally, if it was done by terraform, you'll see the offending Engineer, or if
done via autoscaling, it'll be done by a specialized service account normally
created by Google on our Project.

## Instance Migrations

Many times google will simply migrate a machine.  If there are performance
issues discovered with an instance during a period of time, add this item to
your search as the live migration could be a part of the cause:

```
protoPayload.methodName="migrateOnHostMaintenance"
```

Live migrations may introduce network latency or an intermittent loss of the
node as the machine is brought online on a new physical host.

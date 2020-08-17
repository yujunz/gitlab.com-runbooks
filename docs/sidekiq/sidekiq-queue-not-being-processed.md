# Sidekiq queue no longer being processed

## Symptoms

A Sidekiq queue with a reasonable processing rate 6 hours ago is no longer being
processed. The SidekiqQueueNoLongerBeingProcessed alert may have fired.

Depending on the job build-up rate, alerts for the queue size itself may or may
not be firing yet.

## Resolution

Are metrics being reported from the relevant queues, or is the data missing? Are
these jobs scheduled anywhere (you'll need to check both chef and k8s configs)?

See [large-sidekiq-queue](large-sidekiq-queue.md).

This is a new alert, please update this section with useful findings from
instances of it.

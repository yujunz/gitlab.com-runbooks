<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [How to change how log files are parsed?](#how-to-change-how-log-files-are-parsed)
- [Acknowledge all messages in a single pubsub](#acknowledge-all-messages-in-a-single-pubsub)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## How to change how log files are parsed?

- make the change using Chef, using role attributes for the fluentd cookbook

## Acknowledge all messages in a single pubsub

- stop pubsubbeat
- see the queue going up (silence alert if needed, find the threshold for the alert)
- acknowledge all message in a single pubsub queue

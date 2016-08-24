# Postfix queue is stale/growing

## First and foremost

*Don't Panic*

## Symptoms

* Message in alerts channel _Check_MK: checkmk.gitlap.com service Postfix Queue is CRITICAL_

## Possible checks

* ssh into checkmk.gitlap.com and run `mailq` to inspect the deferred messages
* If most or all deferred messages are for the same recipient there's probably a
problem reaching the server for that address. Else, verify Postfix's configuration.

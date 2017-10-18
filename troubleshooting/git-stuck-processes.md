# Git Stuck Processes

## First and foremost

*Don't Panic*

## Symptoms

There is a large amount of git receive-pack processes in the fleet overview dashboard (at the bottom)

## Reason

Workhorse is not killing connections on a deadline after the client went away, this means that these processes are dangling blocked on IO, effectively doing nothing.

## Prechecks

Count how many processes are dangling, more than 10 is way too much for our current load (this may change over time)

`knife ssh roles:gitlab-fe-git 'ps -eo cmd,pid,etimes= | grep receive-pack | wc -l'`

## Resolution

Kill all the processes that are dangling for more than one hour

`knife ssh roles:gitlab-fe-git 'ps -eo etimes=,pid,cmd,pid | grep receive-pack | awk "{ if (\$1 > 1800) { print \$2 }}" | xargs sudo kill '`

## Postchecks

Review the dashboard to see a drop, and consider running the prechecks again

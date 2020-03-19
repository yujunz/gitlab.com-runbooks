# Alerts that runners manager is down

## Symptoms

Builds are not processed because of runners manager is down.

## Possible checks

1. Try to login to problem node and run `sudo gitlab-runner status`. If gitlab-runner is not running (output is `gitlab-runner: Service is not running!`), consider restart it.

## Resolution

1. Consider restart runners manager by running `sudo service gitlab-runner restart`.

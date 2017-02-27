# Sentry is down and gives error 500

## Symptoms

If sentry.gitlap.com returns http 500 status code.

## Possible checks

1. Login to the sentry.gitlap.com and check `supervisor` service status

    ```
    sudo service supervisor status
    ```

    Start the service if it is down.

1. Check redis service status:


    ```
    sudo service redis-server status
    ```

    Start the service, if it is down.

1. Check postgresql service status:

    ```
    sudo service postgresql status
    ```

   Start the service, if it is down.

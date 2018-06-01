# Sentry is down and gives error 500

## Symptoms

If sentry.gitlap.com returns HTTP 500 status code.

## Possible checks

1. Login to the sentry.gitlap.com, and check that the processes under `supervisor` are running:

    ```
    sudo supervisorctl status
    ```

    A normal output looks as follows:

    ```
    sentry-cron                      RUNNING    pid 58223, uptime 39 days, 11:12:53
    sentry-web                       RUNNING    pid 20067, uptime 0:18:24
    sentry-worker                    RUNNING    pid 58224, uptime 39 days, 11:12:53
    ```

1. If one of the processes is not running, check `/var/log/supervisor/supervisord.log`. More
   detailed logs may also be in `/var/log/supervisor`.

1. To start one of the services that is down (e.g. sentry-web):

    ```
    sudo supervisorctl start sentry-web
    ```

1. Check `supervisor` service is running in the first place:

    ```
    sudo service supervisor status
    ```

    Start the service if it is down.

1. Check Redis service status:


    ```
    sudo service redis-server status
    ```

    Start the service if it is down.

1. Check postgresql service status:

    ```
    sudo service postgresql status
    ```

   Start the service if it is down.

1. Check the status of the Sentry queues:

    ```
    SENTRY_CONF=/etc/sentry /usr/share/nginx/sentry/bin/sentry queues list
    ```

1. If the queues are quite large, you may need to purge them so that recent events will be logged:

    ```
    SENTRY_CONF=/etc/sentry /usr/share/nginx/sentry/bin/sentry queues purge
    ```

    See the [Sentry documentation on monitoring](https://docs.sentry.io/server/monitoring/) for more details.

## Details about Sentry installation

Sentry is comprised of three different processes managed by supervisor:

1. sentry-cron: Runs scheduled jobs via celery
2. sentry-web: Runs the Django framework for the Web frontend/backend
3. sentry-worker: Runs [asynchronous workers](https://docs.sentry.io/server/queue/) to save the data from Redis -> PostgreSQL

* Sentry virtualenv is in /usr/share/nginx/sentry. You can enter the virtualenv via:

    ```
    source /usr/share/nginx/sentry/bin/activate
    ```

* Once activated, you can then run `pip list` to see the packages installed in the environment:

    ```
    (sentry)root@sentry:~# pip list
    ```

* The Sentry supervisord configuration is in `/etc/supervisord/conf.d/sentry.conf`.

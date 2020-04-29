# Sentry is down and gives error 500

## Symptoms

If sentry.gitlab.net returns HTTP 500 status code.

## Possible checks

1. Login to the sentry.gitlab.net, and check that the processes under `supervisor` are running:

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

### Debugging Sentry internals

Sentry is a Django application, and it has a built-in Python shell,
similar to the Rails console, that allows you to access the application
environment. As root:

```shell
SENTRY_CONF="/etc/sentry" /usr/share/nginx/sentry/bin/sentry shell
```

The database can also be accessed via the `postgres` user:

```shell
sudo -u postgres psql -d sentry
```

#### Sessions

This is the authentication flow for Sentry to authenticate GitLab users:

1. Client browser sends a `sentrysid` cookie.
1. Sentry middleware authenticates user from the `sentrysid` payload [via a middleware](https://github.com/getsentry/sentry/blob/0fffc30f1455a23f98e76240fb1bf9de7ef81e71/src/sentry/middleware/auth.py#L22-L40).
1. Django checks the authentication record in the database
(`sentry_authidentity` table) to ensure the user is a member of the
GitLab organization. This record must have two bits in the `flags`
column set properly: `sso:linked` must be `True` and `sso:invalid` must
be `False`. This corresponds to a value of 1 in `flags`.
1. If the record is not valid, then Sentry will ask the user to login to the SSO provider.
1. Periodically, Sentry runs a Celery background job to refresh OAuth2
tokens for all identities in the database. If the refresh step fails,
Sentry will [invalidate bad records by flipping bits in
`flags`](https://github.com/getsentry/sentry/blob/37eb11f6b050fd019375002aed4cf1d8dff2b117/src/sentry/tasks/check_auth.py#L80-L102).

Session cookies are stored in the `sentrysid` cookie on the client
browser. This cookie is a signed payload serialized with the [Django
`PickleSerializer`](https://docs.djangoproject.com/en/3.0/topics/http/sessions/#technical-details).
You can decode the JSON paylod on the host by retrieving the value of
the cookie from the browser, and entering it in the shell. For example,
suppose `sentryid` is `.eJz123456:abcdefg`. You can decode the cookie
via:

```python
from django.core import signing
from django.contrib.sessions.backends.signed_cookies import SessionStore
from django.conf import settings
key = ".eJz123456:abcdefg"
s = SessionStore(key)
s.load()
```

This will return something like:

```python
{   '_auth_user_backend': 'sentry.utils.auth.EmailAuthBackend',
    '_auth_user_id': 13,
    '_nonce': u'1234567',
    'activeorg': u'gitlab',
    'django_language': u'en',
    'sso': u'1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1',
    'sudo': u'ABCDEFG',
    'sudo_redirect_to': u'/account/settings/notifications/',
    u'testcookie': u'worked'}
}
```

### Sentry SSO provider

We currently use this [GitLab SSO
provider](https://github.com/SkyLothar/sentry-auth-gitlab). [This pull
request](https://github.com/SkyLothar/sentry-auth-gitlab/pull/16) is
required to make OAuth2 token refreshes work properly.

### Django ORM lookup examples

To debug using the Django ORM, the following is a quickstart:

```python
from sentry.models import AuthProvider, AuthIdentity, User
user = User.objects.get(id=13)
auth_provider = AuthProvider.objects.get(id=1)
auth_identity = AuthIdentity.objects.get(id=18)
auth_identity.flags

# Manually refreshes an OAuth2 token for a given identity.
# This issues a POST request to /oauth/token with the `refresh_token` grant.
provider = auth_provider.get_provider()
provider.refresh_identity(auth_identity)
```

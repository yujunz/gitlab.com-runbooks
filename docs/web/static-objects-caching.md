# Static objects caching

_See the [HOWTO][howto] for background info._

## Symptoms

* Requests to `/-/archive/` or `/raw/` are failing with 5xx errors
* Alerts about an increase in error rates in gitlab.net zone (where caching solution is hosted)

## Resolution

Check [Sentry][caching-sentry] for the caching solution; sometimes invalid URLs cause an exception
in the worker script.

If a bug in the worker script is causing the errors, consider [disabling the cache][cache-disable].

The application could be responding 5xx errors and the worker is just returning such responses. Check
the application's [Sentry][app-sentry] for clues (most likely other alerts would be triggered if this is the case).

[howto]: static-repository-objects-caching.md
[caching-sentry]: https://sentry.gitlab.net/gitlab/static-objects-caching/
[cache-disable]: static-repository-objects-caching.md#enablingdisabling-external-caching
[app-sentry]: https://sentry.gitlab.net/gitlab/gitlabcom/

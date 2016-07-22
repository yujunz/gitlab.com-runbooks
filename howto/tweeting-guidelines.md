# Tweeting Guidelines

## General Guidelines

We should always be tweeting from @gitlabstatus in an informative but reassuring way.

Avoid using ambiguous messages, but if we don't know what is going on yet just state that we are investigating.

When we have issues with any production operation we should always tweet:

- As soon as we realize that there is an incident going on.
- Periodically when we have findings that are relevant.
- Closing with the resolution and a brief explanation of the root cause.
- Then adding a link to the post-mortem issue in infrastructure.


## Canned messages to avoid thinking

### General "we are investigating an issue"

> We're investigating an issue with GitLab.com Thanks for your patience.

> GitLab.com is back up. Thanks for your patience.

### During deployments

> We'll be deploying GitLab <version> shortly. No downtime is expected but you may see intermittent errors during this time.

> We'll be deploying GitLab <version> at <time> UTC. We will be offline for <time> minutes. Sorry for the inconvenience.

> GitLab.com is now running <version>

> We expect that the migrations for <version> to take only a few minutes, but some users may experience some downtime.

> We are experiencing issues during deploy, we are working on resolving the problem.

> We are experiencing issues during deploy, we are investigating the root cause.

> We are experiencing issues during deploy, we are moving to a downtime deploy because of this.

### We are investigating what's going on

> We are investigating problems with ...

### Database high load

> We are seeing high load in the database, which is causing GitLab.com slowness

> We are still investigating PostgreSQL slowness.

> We are pulling the deploy page to let it cool down forcing a backoff from clients.

> We are still experiencing high load on the database.

> The system metrics appear stable for now. We will continue to monitor PostgreSQL.

### Forcing a failover

> In a couple of minutes from now we will failover our Redis instance, this "should" not cause any downtime for GitLab.com

### Hotfixes

> We deployed a hotfix that prevents a common, slow DB query. We are still investigating the cause of the DB outages.

# Rate of successful user logins is zero

## Reason

The rate of logins (per second) almost never drops below 2 (and even then, only just).  This metric being zero is unprecedented, and suggests something awful has happened.

Also we rely on it being non-zero for the BlockedUserAttemptsIsHigh check to work correctly (to not divide by zero), so calling it out separately avoids missing bad situations.

## Normal situation

On production, normally something between 2 and 5 per second, although this is just the most recent data as at the time of writing and will likely only grow over time.  Mainly: it's never negligible or zero

## What to do

Check the user authentication events dashboard: https://dashboards.gitlab.net/d/JyaDfEWWz/user-authentication-events  This contains a graph with the source data for this alert rule, and other datapoints for context.

There are two broad scenarios where this could alert:

1. Every login is failing (e.g. all users blocked, some other authentication fail)
1. Everything is completely broken and no-one can even begin to login let alone fail.

In the latter case, we expect many other alerts to be going off and the root cause to be clear; this alert is largely for the former case.

In the event the site is up, and it's only logins that are failing, check for action in #announcements, #releases, or #security (@abuse-team) team.  In particular, if blocked user login attempts is large, treat this as though [BlockedUserAttemptsIsHigh](blocked-user-logins.md) was firing.

Other debugging ideas that may provide useful clues:
 * Check whether you can log in to yourself, as your normal account, and as your high priv admin account
 * Confirm whether this affects just production, or potentially staging + ops as well (the latter suggesting some possible external trigger)

And as always the [Triage dashboard]( https://dashboards.gitlab.net/d/RZmbBr7mk/gitlab-triage?orgId=1) is an excellent place to look.

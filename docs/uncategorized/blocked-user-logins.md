# Blocked user login attempts are high

## Reason

We are seeing a higher than the usual (very low) rate of login attempts failing because the user is blocked.  The goal of this alert is to provide a clear signal of cause for an unusual sort of situation that will likely be widely noticed/reported, but for which an underlying reason may be difficult to determine quickly.

## Metric

The rate of login attempts for blocked user accounts as a percentage of the rate of successful logins.

## Normal situation

This metric is normally very low; it sits at literally 0 most of the time, with occasional short bursts, typically not more than 1% for a few minutes, presumably as a freshly blocked abuse source automatedly hammers us for a bit before stopping.

## What to do

Check the user authentication events dashboard: https://dashboards.gitlab.net/d/JyaDfEWWz/user-authentication-events  This contains a graph with the source data for this alert rule, and other datapoints for context.

The metric being higher than expected (an arbitrary threshold set by hand) for an extended period of time implies some sort of issue with our authentication system, e.g. (hypothetically):

1. An abuse blocking operation has caught too many users
1. A bug in a release has caused a large number of users to be blocked, or to be interpreted as blocked
1. Some sort of weirdness with an oAuth partner

Check with #abuse (mostly automated notifications), #security (@abuse-team) for possible abuse related issues.

An active release should show up in the dashboard as an annotation, and #announcements from the deployment tasks.  If it looks possibly related to a release, then check with the people in #releases about details, rollback, and other options.

Other debugging ideas that may provide useful clues:
 * Check whether you can log in to yourself, as your normal account, and/or as your high priv admin account
 * See if the problem is specific to password, password + 2FA, or oAuth type logins.
 * Confirm whether this affects just production, or potentially staging + ops as well (the latter suggesting some possible external trigger)
 * Use the 'type' variable on the dashboard to see if this is specific to a type of backend (git, web, api)

And as always the [Triage dashboard]( https://dashboards.gitlab.net/d/RZmbBr7mk/gitlab-triage?orgId=1) is an excellent place to look.

There is unlikely to be any direct and immediate technical resolution steps that the on-call SRE can take here; mostly it will be alerting and then supporting other teams in diagnosing what's going on.

This is still a somewhat experimental alert; please feel free to reconsider/discuss both the threshold value and the 'for' interval, particularly if this proves to be overly sensitive; the intention is that this should alert only in extreme and surprising situations.

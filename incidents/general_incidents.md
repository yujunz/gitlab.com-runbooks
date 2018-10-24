# Incidents

First: don't panic

If you are feeling overwhelmed, escalate to the [IMOC or CMOC](https://about.gitlab.com/handbook/engineering/infrastructure/incident-management/#roles).  
Whoever is in that role can help you get other people to help with whatever is needed.  Our goal is to resolve the incident in a timely manner, but sometimes that means slowing down and making sure we get the right people involved.  Accuracy is as important or more than speed.

Roles for an incident can be found in the [incident management section of the handbook](https://about.gitlab.com/handbook/engineering/infrastructure/incident-management/)

If you need to start an incident, you can post in the #incident channel(https://gitlab.slack.com/messages/CB7P5CJS1)
If you use /start-incident - a bot will make and issue/google doc and zoom link for you.

## Communication Tools

If you do end up needing to post and update about an incident, we use [Status.io](https://status.io)

On status.io, you can [Make an incident](https://app.status.io/dashboard/5b36dc6502d06804c08349f7/incident/create) and Tweet, post to Slack, IRC, Webhooks, and email via checkboxes on creating or updating the incident.

The incident will also have an affected infrastructure section where you can pick components of the GitLab.com application and the underlying services/containers should we have an incident due to a provider.

You can update incidents with the Update Status button on an existing incident, again you can tweet, etc from that update point.

Remember to close out the incident when the issue is resolved.  Also, when possible, put the issue and/or google doc in the post mortem link.

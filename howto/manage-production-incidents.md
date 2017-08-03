# Production Incidents

## Roles

During an incident there are at least 2 roles, and one more optional


* Production engineers will
  * Open a war room on Zoom immediately to have high a bandwidth communication channel.
  * Create a [Google Doc](https://docs.google.com) to gather the timeline of events.
  * Publish this document using the _File_, _Publish to web..._ function.
  * Make this document GitLab editable by clicking on the `Share` icon and selecting _Advanced_, _Change_, then _On - GitLab_.
  * Tweet `GitLab.com is having a major outage, we're working on resolving it in a Google Doc LINK` with a link to this document to make the community aware.
  * Redact the names to remove the blame. Only use team-member-1, -2, -3, etc.
  * Document partial findings or guessing as we learn.
  * Write a post mortem issue when the incident is solved, and label it with `outage`

* The point person will
  * Handle updating the @gitlabstatus account explaining what is going on in a simple yet reassuring way.
  * Synchronize efforts accross the production engineering team
  * Pull other people in when consultation is needed.
  * Declare a major outage when we are meeting the definition.
  * Post `@channel, we have a major outage and need help creating a live streaming war room, refer to [runbooks-production-incident]` into the #general slack channel.
  * Post `@channel, we have a major outage and need help reviewing public documents` into the #marketing slack channel.
  * Post `@channel, we have a major outage and are working to solve it, you can find the public doc <here>` into the #devrel slack channel.
  * Move the war room to a paid account so the meeting is not time limited.
  * Coordinate with the security team and the communications manager and use the [breach notification policy](https://about.gitlab.com/security/#data-breach-notification-policy) to determine if a breach of user data has occurred and notify any affected users.

* The communications manager will
  * Setup a not time limited Zoom war room and provide it to the point person to move all the production engineers there.
  * Setup Youtube Live Streaming int the war room following [this Zoom guide](https://support.zoom.us/hc/en-us/articles/115000350446-Streaming-a-Webinar-on-YouTube-Live) (for this you will need to have access to the GitLab Youtube account, ask someone from People Ops to grant you so)

* The Marketing representative will
  * Review the Google Doc to provide proper context when needed.
  * Include a note about how is this outage impacting customers in the document.
  * Decide how to handle further communications when the outage is already handled.

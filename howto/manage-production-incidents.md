# Production Incidents

## Roles

During an incident there are at least 2 roles, and one more optional

* Engineer: the person in charge to actually solve the technical problem.
* Point person: the person that is coordinating the resolution of the problem at the technical level.
* Communications manager: the person who manages external communication (setting up the live stream, etc)
* Marketing representative: someone from marketing will need to be involved to review the outage document.

## Definition of a major outage

A major outage is any outage that has a ETA of more than 1h and is disruption the service.

## Minor and major outages management

During a minor outage all the communications will be handled through twitter using the @gitlabstatus account.

During a major outage the work will be distributed in the following way:

* Production engineers will
  * Open a war room on Zoom immediately to have high a bandwidth communication channel.
  * Create a [Google Doc](https://docs.google.com) to gather the timeline of events.
  * Publish this document using the _File_, _Publish to web..._ function.
  * Make this document GitLab editable by clicking on the `Share` icon and selecting _Advanced_, _Change_, then _On - GitLab_.
  * Tweet a link to this document to make the community aware.
  * Redact the names to remove the blame.
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

* The communications manager will
  * Setup a not time limited Zoom war room and provide it to the point person to move all the production engineers there.
  * Setup Youtube Live Streaming int the war room following [this Zoom guide](https://support.zoom.us/hc/en-us/articles/115000350446-Streaming-a-Webinar-on-YouTube-Live) (for this you will need to have access to the GitLab Youtube account, ask someone from People Ops to grant you so)

* The Marketing representative will
  * Review the Google Doc to provide proper context when needed.
  * Include a note about how is this outage impacting customers in the document.
  * Decide how to handle further communications when the outage is already handled.


## Blameless Post Mortems

Refer to the [infrastructure section](https://about.gitlab.com/handbook/infrastructure/) in the handbook for a description on how to write a good post mortem.

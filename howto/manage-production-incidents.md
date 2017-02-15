# Production Incidents

During a major outage it's critical to manage communications in a reassuring manner to show the customers that we are handling the issue in a timely and effective manner.

For this, we designed this set of guidelines to communicate properly and to provide a transparent view into what's going on to he community, allowing them to help us.

It's worth noting that if the incident is critical or too urgent, the name a person who will follow this guideline while you work solving the issue.

## Communication Strategy

* Production:
  * Start a call (war room from now on) immediately to have high a bandwidth communication channel.
  * Open a google doc and make it public for viewing outside of GitLab immediately.
    * Use this document to write the timeline of events as they are known and complete the facts with data as it is found.
    * It's fine to write partial findings or guessing, we just need to validate our assumptions as we go.
    * Redact the names to remove the blame.
    * Tweet a link to this document to make the community aware.
  * Involve the Marketing team by pinging X, Y or Z so they can start working on how to communicate this incident to broader audience while you work on solving the incident.
  * Keep updating the doc with new findings.
  * When the incident is done and we recovered the service, turn the doc into an issue that will be labeled as `outage`. Decide with marketing if in turn this should be a further blog post. In any case open the issue with the timeline to keep a track record in the infrastructure issue tracker.
* Marketing:
  * Make the war room live by default, unless it interferes with solving the incident, or it impacts security or privacy of either a GitLab employee or a customer. Be sure to get approval from the people who is dealing with the outage.
  * Using the public doc, write a blog post explaining the incident and explaining what steps are we taking to solve the incident. Try to include data on how is this incident impacting customers, and specifically which customers are being impacted. Be really clear on how this is affecting on-premises, GitHost and GitLab.com customers.
  * Be sure to be helpful, take ownership of tweeting if production is busy dealing with the incident: a production incident is a stressful situation and all help is greatly received.
  * Help evaluating the impact and the most effective way we can communicate the incident better.
  * Handle communications with the community including the support team so they can also handle the customers expectations.

## Blameless Post Mortems

Refer to the [infrastructure section](https://about.gitlab.com/handbook/infrastructure/) in the handbook for a description on how to write a good post mortem.

# When the lead is away

Sometimes the lead of the production team may not be available to do its job.

When this happens, someone else from the team should take the position and
behave as such to allow the rest of the team to work effectively.

This position can either be explicitly nominated due to vacations, or implicit
due to the Lead not being available for whatever reason. In the former the role
will have a stronger meaning, overriding any other activity performed by the
production engineer, in the latter it will be reduced to only a subset of
activities like taking decisions that could affect the availability of
GitLab.com

## Activities that are performed by the lead

- Triage the infrastructure issue tracker.
- Triage requests from random people, channel them through the issue tracker
  and escalate to the team when necessary.
- Act as an umbrella to avoid team randomization.
- Have a laser focus on availability and performance of GitLab.com.
- Keep the team aligned in the WoW (short term) in regard to the log term
  (~meta ~goal issues) sharing the knowledge when matters
- Fill the role of any other production engineer if the need arises.
- Unblock others

### Triaging

People from within and outside of the company requests actions from the
production team.

These actions may be urgent or they may could be delayed due to the nature of
the issue or the already ongoing efforts of the team.

It is the lead job to go through the issue tracker to triage newly created
issues and complete them with labels so they get automatically sorted by
priority.

It is also part of this job to ask questions in the issues if they are not
clear enough to triage, to identify issues that are duplicated and close them
by stating it so, or to close issues that are out of scope, ill defined or not
actionable.  The lead needs to have a really low tolerance to issues that are
not actionable or do not fit in a single WoW. So feel free to just close those
issues that turn into scope creeps or keep moving the goal post.

A similar thing happens with people making requests in Slack or similar means,
people need things and they will try to get unblocked as soon as possible. This
just happens because we are humans. The job of the lead in this case is to
stand between the people who tries to reach the team directly with direct
requests. What the lead has to do in this case is gently directing people to
the issue tracker, if other people don't have the time to do it, then the lead
should simply open an issue for them and again gently direct the conversation
to the issue tracker.

### Act as an umbrella

Concentration is like a train, it takes a lot of energy to get it started, it
wastes a lot of energy to stop it.  The job of the lead is to prevent the team
from being randomized by any form of events.

Triaging and batching are the best tools to make this happen.

The goal here is to empower the team to work async so everyone can set its own
schedule and manage to get in _the zone_ and stay there for as long as
possible.

The job of the lead is to stand in front of all the possible sources of
interruptions for the team and divert them away from specific team members into
the issue tracker.  This way the team can keep working on what it promised in
the WoW, and doesn't get pulled away in all directions.  To achieve this the one
that gets randomized will be the lead.

### Availability and performance focus

Availability and performance are part of the OKRs of all of the engineering
organization at GitLab.

Because of this, the lead has to have a laser focus on improving performance in
GitLab.com as much as possible given the application constraints.  This means
that whenever we have a chance to gather data to improve performance or
availability we should prioritize it as much as possible. This could mean
changing the WoW, or it could mean taking action on its own hands to gather
data and plan the next steps.

### Keep the team aligned with the WoW

As the team is focusing on delivering the things that we promised we will
deliver they are not paying attention to the grand scheme of things. Because of
this the lead will need to nudge and adjust the team direction to focus on
delivering the things that are in the WoW and that are labeled as goals. This
could mean asking for status, pinging people, or doing whatever is necessary to
unblock the work.

This could also mean dropping and closing issues that are not longer relevant
for the long term goals, or changing the WoW to adjust it if the priority has
changed due to any possible emergency.

Additionally, the lead will need to share the context with the team for when
adjustments happen so everyone is on the same page and understand the reasoning
behind the direction adjustment.

#### Scheduling tasks

Every Wednesday morning UTC, the acting lead will perform housekeeping of the
current WoW by moving all the issues that are still open to the next one and
adding ~"moved X" labels to issues that were goals and were not delivered
during the WoW time.  Then rename and close the old WoW as _WoW ended <date>_,
rename the _Next WoW_ to _WoW_ and then create a new _Next WoW_ for future
planning.

Before starting the new WoW the lead will also check that the ~goal issues are
aligned with the longer term ~meta ~goal issues and properly scoped given what
the team can actually do in a single WoW.  As a rule of thumb we should be only
adding a 20% of planned work to a WoW because there will be a hidden 30% that
will pop up from the scheduled work due to the nature of fast iteration, and a
50% unscheduled work that will just happen.

### Unblock others

We should try to keep the rest of the company unblocked as much as possible.

In reality, this goes hand in hand with being an umbrella for interruption and
long term planning, meaning that people will request things, we should do our
best to batch them and deliver in the best possible time and form, without
interrupting the current work flow or randomizing the team.

The job of the lead here is to find the balance between unblocking and
delivering the promised goals.  Again, the tools are the issue tracker and
batching of requests.

### Fill the role of any other Production Engineer

We are all in this together.

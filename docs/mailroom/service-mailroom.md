<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Mailroom Service

* **Responsible Teams**:
  * [create](https://about.gitlab.com/handbook/engineering/dev-backend/create/). **Slack Channel**: [#g_create](https://gitlab.slack.com/archives/g_create)
  * [distribution](https://about.gitlab.com/handbook/engineering/dev-backend/distribution/). **Slack Channel**: [#distribution](https://gitlab.slack.com/archives/distribution)
  * [geo](https://about.gitlab.com/handbook/engineering/dev-backend/geo/). **Slack Channel**: [#g_geo](https://gitlab.slack.com/archives/g_geo)
  * [gitaly](https://about.gitlab.com/handbook/engineering/dev-backend/gitaly/). **Slack Channel**: [#gitaly](https://gitlab.slack.com/archives/gitaly)
  * [gitter](https://about.gitlab.com/handbook/engineering/dev-backend/gitter/). **Slack Channel**: [#g_gitaly](https://gitlab.slack.com/archives/g_gitaly)
  * [manage](https://about.gitlab.com/handbook/engineering/dev-backend/manage/). **Slack Channel**: [#g_manage](https://gitlab.slack.com/archives/g_manage)
  * [plan](https://about.gitlab.com/handbook/engineering/dev-backend/manage/). **Slack Channel**: [#g_plan](https://gitlab.slack.com/archives/g_plan)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=mailroom&orgId=1
* **Alerts**: https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22mailroom%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Mailroom"

## Logging

* [system](https://log.gprd.gitlab.net/goto/0ce3bf67abafcfc0f81f3d6e7a066912)

## Troubleshooting Pointers

* [../logging/README.md](../logging/README.md)
* [../uncategorized/k8s-gitlab-operations.md](../uncategorized/k8s-gitlab-operations.md)
<!-- END_MARKER -->

## Operations

### Infrastructure

The mailroom service runs in the production GKE cluster, in the `gitlab`
namespace.

### Configuration

Mailroom depends on being able to read mail from IMAP and a connection to
redis-sidekiq so that it can queue events on the `email_receiver` queue.

After events are delivered to sidekiq messages are deleted from the IMAP
mailbox.

### Clear e-mail that are piling up

If for some reason Mailroom is unable to process email, an alert will let us
know.  If that alert does not clear, we may need to manually intervene .
Utilize this process to clear the unread count which will force Mailroom to
reattempt to process the email.

* Clear the unread count
From a gitlab-console session:
```
imap = Net::IMAP.new("imap.gmail.com", 993, :ssl => true)
config = Gitlab::MailRoom.config
imap.login("incoming@gitlab.com", config[:password])
imap.select("inbox")
imap.uid_search("UNSEEN")
```

#### Cleanup

```
h = Mail.read_from_string(imap.uid_fetch(<ID>, "RFC822.HEADER")[0].attr["RFC822.HEADER"])
puts "@#{h.date.to_time} from #{h.from.first} to #{h.to.first}.  Subject: #{h.subject}"
```

Note that:

1. `imap.uid_fetch` of the header does a peek that doesn't change the seen
   flags, from which you can, with some visual effort, see the date and decide
   if we want to mark it seen (i.e. ignore it)
1. The to address encodes the namespace/project, so is handy to see. Decide if
   the message too old to want to ingest now (i.e. it would be confusing to
   customers if the message were to suddenly appear on the issue many days or
   weeks after it was sent).  I've been typically considering a couple of days
   as an upper limit, but use your discretion including thinking on the
   from/to/subject e.g. bot responses from 3 weeks ago with a subject of "Error
   fetching data from FOO" are probably irrelevant at more than a very short
   remove, and the message can be ignored.

To mark them seen (ignore them):

```
imap.uid_fetch(<ID>, "RFC822")
```

Fetching the full message marks it as seen.  This will stop mail_room trying to
process it, but not delete it so we are able to review and ingest it later if we
so choose.  Obviously we don't want too many of these, but we can live with even
a few thousand without ill effect.

To do this in a loop asking you what to do for each message:

```
imap.uid_search("UNSEEN").each do |message_id|
  puts "Checking #{message_id}"
  h = Mail.read_from_string(imap.uid_fetch(message_id, "RFC822.HEADER")[0].attr["RFC822.HEADER"])
  puts "@#{h.date.to_time} from #{h.from.first} to #{h.to.first}.  Subject: #{h.subject}"
  puts "Mark this message as seen? (y/N)"
  input = gets.strip
  imap.uid_fetch(message_id, "RFC822") if /[yY]/.match?(input)
end
```

If you want to clear out some obvious ones (e.g. bots) then re-evaluate, feel
free to run this multiple times; it will only show the remaining UNSEEN messages
each run.  Once you've marked as seen all mails you do NOT want to be ingested,
you need to force it to re-ingest.  Stop mail_room on *all* Mailroom servers for
the environment for slightly more than 10 minutes, then start it on one of them,
wait 30-60 seconds, then start it on the others.  This lets the TTL for the key
expire in Redis to allow it to pick up the messages again.  One could directly
manage Redis by deleting the key, however, this procedure is higher in risk.
Mail ingest is paused for 10 minutes, but SMTP is async and can have delays, so
this is reasonable from a raw technical standpoint.

### Expunging Emails

Currently emails are sent to the trash, but they are not, by default, expunged.
Utilize this process to remove those emails.  This is a lightweight process that
operates at roughly 100 messages per second.  The only time this is needed is if
something happened with Mailroom's ability to expunge emails and the amount of
left over deleted emails is building up over time.

* ssh into a console server for the environment which fired the alert
* grab the password from `gitlab.rb` under attribute
  `gitlab_rails['incoming_email_password']`
* Expunge

```
sudo gitlab-rails c
imap = Net::IMAP.new("imap.gmail.com", 993, :ssl => true)
imap.login("incoming@gitlab.com", "REDACTED")
imap.uid_search("DELETED").length # Informational, shows how many messages are deleted but not expunged
imap.expunge()
```

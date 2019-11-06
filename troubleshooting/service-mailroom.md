<!-- MARKER: do not edit this section directly. Edit services/service-mappings.yml then run scripts/generate-docs -->
#  Mailroom Service

* **Responsible Team**: [backend](https://about.gitlab.com/handbook/engineering/dev-backend/)
* **Slack Channel**: [#backend](https://gitlab.slack.com/archives/backend)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/WOtyonOiz/general-triage-service?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=mailroom&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22mailroom%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Mailroom"

## Logging

* [system](https://log.gitlab.net/goto/0ce3bf67abafcfc0f81f3d6e7a066912)

<!-- END_MARKER -->

## Operations

### Clear e-mail that are piling up

Until we are able to [upgrade Mailroom], there exists the possibility that a
problem occurred when processing a message via Mailroom which can sometimes
leave emails hanging around in the inbox until manual intervention.  Utilize
this process to clear the unread count which will force Mailroom to reattempt to
process the email.

* ssh into the console server for the environment which fired the alert
* grab the password from `gitlab.rb` under attribute
  `gitlab_rails['incoming_email_password']`
* Clear the unread count

```
sudo gitlab-rails c
require 'mail_room'
require 'mail'
imap = MailRoom::IMAP.new("imap.gmail.com", 993, :ssl => true)
imap.login("incoming@gitlab.com", "REDACTED")
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
operates at roughly 100 messages per second.  Eventually we shouldn't need to do
this after we [upgrade Mailroom].

* ssh into the console server for the environment which fired the alert
* grab the password from `gitlab.rb` under attribute
  `gitlab_rails['incoming_email_password']`
* Expunge

```
sudo gitlab-rails c
require 'mail_room'
require 'mail'
imap = MailRoom::IMAP.new("imap.gmail.com", 993, :ssl => true)
imap.login("incoming@gitlab.com", "REDACTED")
imap.uid_search("DELETED").length # Informational, shows how many messages are deleted but not expunged
imap.expunge()
```

[upgrade Mailroom]: https://gitlab.com/gitlab-org/gitlab/issues/35108

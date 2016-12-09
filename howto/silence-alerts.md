## View alerts

1. Incoming alerts, which are being triggered can be viewed on https://alerts.gitlab.com/#/alerts
1. Silences are a straightforward way to simply mute alerts for a given time. A silence is configured based on matchers, just like the routing tree. Incoming alerts are checked whether they match all the equality or regular expression matchers of an active silence. If they do, no notifications will be sent out for that alert. Silenced alerts can be viewed on https://alerts.gitlab.com/#/silences 

## How to silence alerts

Silences can be added in two ways:
1. By explicitly creating silence (`New Silence` button) on [silences](https://alerts.gitlab.com/#/silences) page. Enter start, end, creator, reason and condition for silencing. Note that regular expression can be used to match many alerts.
![silence example](../img/manual-silence-example.png)
1. By silencing from [alerts] page. Conditions for silencing automatically taken from alert labels.
![silence example](../img/alert-silence-example.png)
1. You can unsilence alert by clicking `Expire` on silence entry.

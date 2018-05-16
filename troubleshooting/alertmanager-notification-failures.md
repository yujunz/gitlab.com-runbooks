# Alertmanager Notification Failures

## Symptoms

Alertmanager is getting errors trying to send alerts. Alerts will be
lost.

## Possible checks

Check the log at `/var/log/prometheus/alertmanager/current` on the
machine where alertmanager is running (it should be the fqdn label on
the alert).

Note the "integration" label on the alert. If it's only one
integration it's probably a problem with the setup of that
integration.

For example if it's slack you can get the API key by looking for
"api_url" in `/opt/prometheus/alertmanager/alertmanager.yml`

And you can test it with curl

```
curl -X POST -H 'Content-type: application/json' \
 --data '{"text":"Ceci cest un test."}' \
 https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX
```

If it receives a 404 result then the channel does not exist. See [slack docs](https://api.slack.com/changelog/2016-05-17-changes-to-errors-for-incoming-webhooks) for other possible error codes.

For more information see https://api.slack.com/incoming-webhooks

## Resolution


## Symptoms

You see messages like the following on a pubsubbeat log:

```
WARN    elasticsearch/client.go:502    Cannot index event publisher.Event{Content:beat.Event{[A BUNCH OF EVENT DATA]} (status=400): {"type":"mapper_parsing_exception","reason":"object mapping for [json.peer.address] tried to parse field [peer.address] as object, but found a concrete value"}
```

## Likely suspects

Most likely, this is caused by a format change in a component's log output. ES
automatically deduct the mapping for an index from the first message it
processes, and will fail if further messages don't match that mapping.

## Resolution

Existing fields mappings [cannot be updated](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html#_updating_existing_field_mappings),
but since [set our indexes name with the current day](https://gitlab.com/gitlab-cookbooks/gitlab-elk/blob/3cfa7707a99b8b23a795e4104c564b39e94e2c23/attributes/default.rb#L62)
the following day's index should create the mapping matching the new log
structure and logging should resume working correctly. If you need to fix the
issue before that you can override the index name on the appropiate pubsub
node's `/opt/pubsubbeat/pubsubbeat.yml` (property `output.elasticsearch.index`)
and restart the pubsub service on that node. You should rollback that change
afterwards.

# Log view in Kibana

## Kibana URL

Kibana can be reached on https://log.gitlab.net

Before providing screens/information from Kibana, set/check that your timezone in Kibana is UTC. It will be easier to understand provided information for you and other team members. Timezone can be set in `Settings->Advanced->dateFormat:tz->UTC`.

## Filter logs by queries

In Kibana `program` stands for application and `hostname` for machine where it runs. For example, to find all logs from `worker2` for `mailroom` you need to provide this query - `program:mailroom AND hostname:worker2`

Queries can be constructed via constructor, but there is only top 5 values to select for each parameter for specified amount of time. By default it is last 15 minutes.

## Kubernetes

Look for assistance with Kubernetes Logs here:
[../troubleshooting/kubernetes.md](../troubleshooting/kubernetes.md)


## Adding new log patterns to parse

By modifying file `files/default/logstash-gitlab.conf` in `gitlab-elk` cookbook you can add/remove/modify parsing of logstash file parsing.

This file contains grok patterns, which can be tested in - https://grokdebug.herokuapp.com/ (simple) or http://grokconstructor.appspot.com/do/match (more advanced)


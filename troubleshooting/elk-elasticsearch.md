# SSL Certificate expiring or expired

## First and foremost

*Don't Panic*

## Symptoms

You're seeing alerts like

```
@channel Elasticsearch on log-es3.gitlap.com is down
```

## Possible checks

1. Login to the corresponding node
1. Check elastic with `curl http://localhost:9200`

## Resolution

Restart elasticsearch service with the following command on corresponding node:

```
sudo service elasticsearch restart
```

### Verify that elasticsearch is started

1. Check that the service is started `sudo service elasticsearch status`
1. Check http endpoint with the `curl http://localhost:9200`
1. Verify that the cluster is operable - `curl http://localhost:9200/_cluster/health?pretty`
1. Verify that that there is no `initializing_shards` and `unassigned_shards`. Cluster not operable at that moment and you should only wait while all shards moved to the `active` state. You can check it with the `curl http://localhost:9200/_cat/shards?v`.
1. Verify that the cluster in `green` status. Otherwise - start elasticsearch for all nodes. Alerts for corresponding nodes will be alerted too.

## Notes

* There is only `log-es(2|3|4).gitlap.com` nodes.

[ELK performance dashboard]: https://dashboards.gitlab.net/dashboard/db/elk-stats?orgId=1

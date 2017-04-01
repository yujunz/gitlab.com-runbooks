### How to run commands for ES

1. ES on `log-esX` is accessible from the logstash node (log.gitlap.com).
1. Run Elastic API command against any of the ES instance. Since our ES instances in one cluster, you can run your query against any of the instance, result will be the same.

### How to check cluster health

1. `curl http://<es node>:9200/_cluster/health?pretty`

### How to view shards distribution

1. `curl http://<es node>:9200/_cat/shards?v`. You can pipe your output to `sort` to see sorted result.
1. To see shards for specific index, you can use `curl http://<es node>:9200/_cat/shards/logstash-2017.04.01?v`. Logstash creates new index everyday with such pattern - `logstash-YYYY.MM.DD`.

### How to move (relocate) shard from one ES instance to another one.
```
curl -XPOST '<es node>:9200/_cluster/reroute' -d '{
    "commands" : [
        {
          "move" : {
                "index" : "logstash-2017.04.01", "shard" : 5,
                "from_node" : "log-es3", "to_node": "log-es4"
          }
        }
    ]
}'

```

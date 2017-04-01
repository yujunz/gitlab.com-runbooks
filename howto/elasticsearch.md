### How to run commands for ES

1. ES on `log-esX` is accessible from the logstash node (log.gitlap.com).
1. Run Elastic API command against any of the ES instance. Since our ES instances in one cluster, you can run your query against any of the instance, result will be the same.

### How to check cluster health

1. `curl http://localhost:9200/_cluster/health?pretty`

### How to view shards distribution

1. `curl http://localhost:9200/_cat/shards?v`. You can pipe your output to `sort` to see sorted result.
1. To see shards for specific index, you can use `curl http://<es node>:9200/_cat/shards/logstash-2017.04.01?v`. Logstash creates new index everyday with such pattern - `logstash-YYYY.MM.DD`.

### How to move (relocate) shard from one ES instance to another one (ES 5.x)
```
curl -XPOST 'localhost:9200/_cluster/reroute' -d '{
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

### Current node allocation

Show the current node allocation. This will tell you which nodes are available, how many shards each has, and how much disk space is being used/available:

```
curl -s 'localhost:9200/_cat/allocation?v'
```

### Number of threads

Show the current Elasticsearch threads. Look particularly at the number of bulk entries that are queued. If the number is high, data is not being ingested fast enough.
```
curl 'http://localhost:9200/_cat/thread_pool?v'
```

### Current logstash template

```
curl http://localhost:9200/_template/logstash?pretty
```

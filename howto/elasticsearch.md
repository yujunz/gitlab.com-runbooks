### How to run commands for ES

1. ES on `log-esX` is accessible from the logstash node (log.gitlab.net).
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

### Create new index

```
curl -XPUT localhost:9200/gitlab -d '{
  "settings": {
    "index" : {
      "number_of_shards" : 120,
      "number_of_replicas": 1
    }
  }
}'
```

### How to enable/disable ES integration in Gitlab

#### ES integration admin page ####

go to gitlab's admin panel, navigate to Settings -> [Integrations] -> Elasticsearch -> [Expand] (example URL: `https://gitlab.com/admin/application_settings/integrations`)

#### enabling ES integration ####

Before you make any changes to config and click save, make sure you are aware of which namespaces will be indexed! consider:
- if you enable elasticsearch integration by just using the "Elasticsearch indexing" checkbox and clicking save, the entire instance will be indexed
- if you only want to enable indexing for a specific namespace, use the limiting feature and only then click save
- in order to allow for initial indexing to take place (which depending on the size of the instance can take a few hours/days) without breaking the search feature, do not enable searching with Elasticsearch. Do it after the initial indexing.

#### disabling ES integration ####

Disabling the elasticsearch integration (unticking the box and clicking save) will disable all integration related features in gitlab (e.g. there should be no further search requests to the ES cluster).

However, disabling the integration does not kill the ongoing sidekiq jobs and does not remove them from the queue. This means that if for example you accidentally enabled the integration on a huge instance, which resulted in lots of sidekiq jobs being created and enqueued, and your cluster got overwhelmed, simply disabling the integration will only prevent creation of new jobs, but will not get rid of existing ones.

To remove jobs from queues and kill running ones follow the steps described in `troubleshooting/large-sidekiq-queue.md` in this repo. After you removed all jobs, check monitoring metrics of the ES cluster to see if indexing requests stopped coming in. You should also keep an eye on [logs in kibana](https://log.gitlab.net/goto/370fba905cd3f79770854466210ec506)

*Note*
You might want to remove namespaces from the list of indexed namespaces (e.g. to prevent creation of new elastic_namespace_indexer jobs). There is a [bug](https://gitlab.com/gitlab-org/gitlab-ee/issues/11225) which prevents removal of indexed namespaces from the admin panel, for this reason it has to be done from the console. See the description of the linked issue for more info on how to do it.

*Note*
when the integration is enabled, new jobs are scheduled even if no namespaces are on the list

*Note*
an example procedure that should cover all edge cases (nuclear option, will wipe out everything related to elastic):
1. disable ES integration in the admin panel
1. remove all namespace objects using console commands in the bug above
1. recreate index using rake task
1. clear index status using rake task
1. watch ES monitoring and Kibana logs

#### disabling elastic backed search, but leaving the integration on ####

you can prevent Gitlab from using ES integration for searching, but leave the integration itself enabled. An example of when this is useful is during initial indexing.

#### ES integration docs ####

more detailed instructions and docs: https://docs.gitlab.com/ee/integration/elasticsearch.html

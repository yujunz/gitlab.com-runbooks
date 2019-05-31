### ES integration docs ###

more detailed instructions and docs: https://docs.gitlab.com/ee/integration/elasticsearch.html

### ES integration admin page ###

go to gitlab's admin panel, navigate to Settings -> [Integrations] -> Elasticsearch -> [Expand] (URL: `https://gitlab.com/admin/application_settings/integrations`)

### enabling ES integration ###

Before you make any changes to config and click save, make sure you are aware of which namespaces will be indexed! consider:
- if you enable elasticsearch integration by just using the "Elasticsearch indexing" checkbox and clicking save, the entire instance will be indexed
- if you only want to enable indexing for a specific namespace, use the limiting feature and only then click save
- in order to allow for initial indexing to take place (which depending on the size of the instance can take a few hours/days) without breaking the search feature, do not enable searching with Elasticsearch. Do it after the initial indexing.

### disabling ES integration ###

Disabling the elasticsearch integration (unticking the box and clicking save) will disable all integration related features in gitlab (e.g. there should be no further search requests to the ES cluster).

1. go to ES integration admin page (see above)
1. untick the box for ES indexing
1. click save
1. All search queries should now use the regular Gitlab search mechanism

### disabling ES integration did not help ###

Disabling the integration does not kill the ongoing sidekiq jobs and does not remove them from the queue. This means that if for example you accidentally enabled the integration on a huge instance, which resulted in lots of sidekiq jobs being created and enqueued, and your cluster got overwhelmed, simply disabling the integration will only prevent creation of new jobs, but will not get rid of existing ones.

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

### disabling elastic backed search, but leaving the integration on ###

you can prevent Gitlab from using ES integration for searching, but leave the integration itself enabled. An example of when this is useful is during initial indexing.

### creating and removing indexes ###

TL;DR:
1. the rake task that creates the index is also setting up mapping, so the easiest way to create the index is by using [the rake task](https://docs.gitlab.com/ee/integration/elasticsearch.html#gitlab-elasticsearch-rake-tasks). If you don't use the rake task you'll have to create mappings yourself!
1. removing can be done through kibana's index management page. Alternatively, the index can be wiped by recreating it (using the rake task).

#### creating an index (shards management) ####

At the time of writing, the rake task does not allow you to specify the number of shards ( https://gitlab.com/gitlab-org/gitlab-ee/issues/2087 ). This will result in number_of_routing_shards being set to 5 and this prevents the index from being split.

you can only split the index if you have a sufficient number of routing_shards. The number_of_routing_shards translates to the number of keys in the hashing table so it cannot be adjusted after the index has been created.

ELK 6.x will by default create as many routing shards as there were shards defined during index creation. By default, indeces are created with 5 shards, which means that by default there will be 5 routing shards, which means you cannot split the index once it's created using defaults.

ELK 7.x by default uses a very high number of routing shards which allows you to split the index.

### shards management ###

at the moment, data is distributed across shards unevenly [7238](https://gitlab.com/gitlab-org/gitlab-ee/issues/7238) , [3217](https://gitlab.com/gitlab-org/gitlab-ee/issues/3217) , [2957](https://gitlab.com/gitlab-org/gitlab-ee/issues/2957)

if needed, rebalancing of shards can be done through API

### clean up ###

Q: will we ever remove data from the index? e.g. when a project is removed from gitlab instance? do we not care about leftovers? how can we monitor how much data is stale?

A: data is removed from the elasticsearch index when it is removed from the GitLab database or filesystem. When a project is removed, we delete corresponding documents from the index. Similarly, if an issue is removed, then the elasticsearch document for that index is also removed. The only way to discover if a particular document in elasticsearch is stale compared to the database is to cross-reference between the two. There's nothing automatic for that at present, and it sounds expensive to do.

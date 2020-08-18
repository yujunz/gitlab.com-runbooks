local toolingLinkDefinition = (import './tooling_link_definition.libsonnet').toolingLinkDefinition;
local elasticsearchLinks = import 'elasticlinkbuilder/elasticsearch_links.libsonnet';

{
  kibana(
    title,
    index,
    type=null,
    stage=null,
    durationField=null,
    slowQueryValue=null,
    httpStatusCodeField=null,
  )::
    local filters =
      (
        if type == null then
          []
        else
          [elasticsearchLinks.matchFilter('json.type', type)]
      )
      +
      (
        if stage == null then
          []
        else
          [elasticsearchLinks.matchFilter('json.stage', stage)]
      );


    [
      toolingLinkDefinition({
        title: 'Kibana/Discover: ' + title + " logs",
        url: elasticsearchLinks.buildElasticDiscoverSearchQueryURL(index, filters),
      })
    ]
    +
    (
      if durationField != null && slowQueryValue != null then
        [
          toolingLinkDefinition({
            title: 'Kibana/Discover: ' + title + " slow request logs",
            url: elasticsearchLinks.buildElasticDiscoverSearchQueryURL(index, filters + [
              elasticsearchLinks.rangeFilter(durationField, slowQueryValue, null)
            ]),
          })
        ]
      else []
    )
    +
    (
      if httpStatusCodeField != null then
        [
          toolingLinkDefinition({
            title: 'Kibana/Discover: ' + title + " failed request logs",
            url: elasticsearchLinks.buildElasticDiscoverSearchQueryURL(index, filters + [
              elasticsearchLinks.rangeFilter(httpStatusCodeField, 500, null)
            ]),
          })
        ]
      else []
    )
    +
    [
      toolingLinkDefinition({
        title: 'Kibana/Visualize: ' + title + " requests",
        url: elasticsearchLinks.buildElasticLineCountVizURL(index, filters),
      })
    ]
    +
    (
      if httpStatusCodeField != null then
        [
          toolingLinkDefinition({
            title: 'Kibana/Visualize: ' + title + " failed request",
            url: elasticsearchLinks.buildElasticLineCountVizURL(index, filters + [
              elasticsearchLinks.rangeFilter(httpStatusCodeField, 500, null)
            ]),
          })
        ]
      else []
    )
    +
    (
      if durationField != null then
        [
          toolingLinkDefinition({
            title: 'Kibana/Visualize: ' + title + " request latencies",
            url: elasticsearchLinks.buildElasticLinePercentileVizURL(index, filters, durationField),
          })
        ]
      else []
    )
}

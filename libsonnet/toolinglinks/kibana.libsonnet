local toolingLinkDefinition = (import './tooling_link_definition.libsonnet').toolingLinkDefinition;
local elasticsearchLinks = import 'elasticlinkbuilder/elasticsearch_links.libsonnet';

{
  kibana(
    title,
    index,
    type=null,
    stage=null,
    tag=null,
    shard=null,
    slowRequestSeconds=null,
    matches={},
  )::
    local supportsFailures = elasticsearchLinks.indexSupportsFailureQueries(index);
    local supportsLatencies = elasticsearchLinks.indexSupportsLatencyQueries(index);

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
      )
      +
      (
        if tag == null then
          []
        else
          [elasticsearchLinks.matchFilter('json.tag', tag)]
      )
      +
      (
        if shard == null then
          []
        else
          [elasticsearchLinks.matchFilter('json.shard', shard)]
      )
      +
      [
        elasticsearchLinks.matchFilter(k, matches[k])
        for k in std.objectFields(matches)
      ];

    [
      toolingLinkDefinition({
        title: '📖 Kibana: ' + title + ' logs',
        url: elasticsearchLinks.buildElasticDiscoverSearchQueryURL(index, filters),
      }),
    ]
    +
    (
      if supportsLatencies && slowRequestSeconds != null then
        [
          toolingLinkDefinition({
            title: '📖 Kibana: ' + title + ' slow request logs',
            url: elasticsearchLinks.buildElasticDiscoverSlowRequestSearchQueryURL(index, filters, slowRequestSeconds=slowRequestSeconds),
          }),
        ]
      else []
    )
    +
    (
      if supportsFailures then
        [
          toolingLinkDefinition({
            title: '📖 Kibana: ' + title + ' failed request logs',
            url: elasticsearchLinks.buildElasticDiscoverFailureSearchQueryURL(index, filters),
          }),
        ]
      else
        []
    )
    +
    [
      toolingLinkDefinition({
        title: '📈 Kibana: ' + title + ' requests',
        url: elasticsearchLinks.buildElasticLineCountVizURL(index, filters),
      }),

    ]
    +
    (
      if supportsFailures then
        [
          toolingLinkDefinition({
            title: '📈 Kibana: ' + title + ' failed requests',
            url: elasticsearchLinks.buildElasticLineFailureCountVizURL(index, filters),
          }),
        ]
      else
        []
    )
    +
    (
      if supportsLatencies then
        [
          toolingLinkDefinition({
            title: '📈 Kibana: ' + title + ' sum latency aggregated',
            url: elasticsearchLinks.buildElasticLineTotalDurationVizURL(index, filters, splitSeries=true),
          }),
          toolingLinkDefinition({
            title: '📈 Kibana: ' + title + ' sum latency aggregated (split)',
            url: elasticsearchLinks.buildElasticLineTotalDurationVizURL(index, filters, splitSeries=true),
          }),
          toolingLinkDefinition({
            title: '📈 Kibana: ' + title + ' percentile latency aggregated',
            url: elasticsearchLinks.buildElasticLinePercentileVizURL(index, filters, splitSeries=false),
          }),
          toolingLinkDefinition({
            title: '📈 Kibana: ' + title + ' percentile latency aggregated (split)',
            url: elasticsearchLinks.buildElasticLinePercentileVizURL(index, filters, splitSeries=true),
          }),
        ]
      else
        []
    ),
}

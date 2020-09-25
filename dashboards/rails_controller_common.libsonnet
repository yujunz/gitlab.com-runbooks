local elasticsearchLinks = import 'elasticlinkbuilder/elasticsearch_links.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local templates = import 'grafana/templates.libsonnet';

local row = grafana.row;

local rowGrid(rowTitle, panels, startRow) =
  [
    row.new(title=rowTitle) { gridPos: { x: 0, y: startRow, w: 24, h: 1 } },
  ] +
  layout.grid(panels, cols=std.length(panels), startRow=startRow + 1);

local elasticsearchLogSearchDataLink(type) = {
  url: elasticsearchLinks.buildElasticDiscoverSearchQueryURL(
    'rails',
    [
      elasticsearchLinks.matchFilter('json.type.keyword', type),
      elasticsearchLinks.matchFilter('json.controller.keyword', '$controller'),
    ],
    ['json.action.keyword:${action:lucene}']
  ),
  title: 'ElasticSearch: Rails logs',
  targetBlank: true,
};

{
  dashboard(type, defaultController, defaultAction)::
    local selector = 'environment="$environment", type="%s", stage="$stage", controller="$controller", action=~"$action"' % type;

    basic.dashboard(
      'Rails Controller',
      tags=['type:%s' % type, 'detail'],
      includeEnvironmentTemplate=true,
    )
    .addTemplate(templates.constant('type', type))
    .addTemplate(templates.stage)
    .addTemplate(templates.railsController(defaultController))
    .addTemplate(templates.railsControllerAction(defaultAction))
    .addPanels(
      layout.grid([
        basic.timeseries(
          stableId='request-rate',
          title='Request Rate',
          query='avg_over_time(controller_action:gitlab_transaction_duration_seconds_count:rate1m{%s}[$__interval])' % selector,
          legendFormat='{{ action }}',
          format='ops',
          yAxisLabel='Requests per Second',
        ).addDataLink(elasticsearchLogSearchDataLink(type)),
        basic.multiTimeseries(
          stableId='latency',
          title='Latency',
          queries=[{
            query: 'avg_over_time(controller_action:gitlab_transaction_duration_seconds:p99{%s}[$__interval])' % selector,
            legendFormat: '{{ action }} - p99',
          }, {
            query: 'avg_over_time(controller_action:gitlab_transaction_duration_seconds:p95{%s}[$__interval])' % selector,
            legendFormat: '{{ action }} - p95',
          }, {
            query: |||
              avg_over_time(controller_action:gitlab_transaction_duration_seconds_sum:rate1m{%(selector)s}[$__interval])
              /
              avg_over_time(controller_action:gitlab_transaction_duration_seconds_count:rate1m{%(selector)s}[$__interval])
            ||| % { selector: selector },
            legendFormat: '{{ action }} - mean',
          }],
          format='s',
        ).addDataLink(elasticsearchLogSearchDataLink(type)),
      ])
      +
      rowGrid('SQL', [
        basic.timeseries(
          stableId='sql-requests-per-controller-request',
          title='SQL Requests per Controller Request',
          query=|||
            sum without (fqdn,instance) (
            rate(gitlab_sql_duration_seconds_count{%(selector)s}[$__interval])
            )
            /
            avg_over_time(controller_action:gitlab_transaction_duration_seconds_count:rate1m{%(selector)s}[$__interval])
          ||| % { selector: selector },
          legendFormat='{{ action }}',
        ),
        basic.timeseries(
          stableId='sql-latency-per-controller-request',
          title='SQL Latency per Controller Request',
          query=|||
            avg_over_time(controller_action:gitlab_sql_duration_seconds_sum:rate1m{%(selector)s}[$__interval])
            /
            avg_over_time(controller_action:gitlab_transaction_duration_seconds_count:rate1m{%(selector)s}[$__interval])
          ||| % { selector: selector },
          legendFormat='{{ action }}',
          format='s'
        ),
        basic.timeseries(
          stableId='sql-latency-per-sql-request',
          title='SQL Latency per SQL Request',
          query=|||
            sum without (fqdn,instance) (
            rate(gitlab_sql_duration_seconds_sum{%(selector)s}[$__interval])
            )
            /
            sum without (fqdn,instance) (
            rate(gitlab_sql_duration_seconds_count{%(selector)s}[$__interval])
            )
          ||| % { selector: selector },
          legendFormat='{{ action }}',
          format='s'
        ),
      ], startRow=201)
      +
      rowGrid('Cache', [
        basic.timeseries(
          stableId='cache-operations',
          title='Cache Operations',
          query=|||
            sum without (fqdn, instance) (
            rate(gitlab_cache_operations_total{%(selector)s}[$__interval])
            )
          ||| % { selector: selector },
          legendFormat='{{ operation }}',
        ),
      ], startRow=301)
      +
      layout.grid([])
    )
    .trailer(),
}

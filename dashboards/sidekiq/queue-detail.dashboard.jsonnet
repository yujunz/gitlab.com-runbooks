local basic = import 'basic.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local layout = import 'layout.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local link = grafana.link;
local template = grafana.template;
local annotation = grafana.annotation;
local serviceCatalog = import 'service_catalog.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local sidekiqHelpers = import 'services/lib/sidekiq-helpers.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local row = grafana.row;
local elasticsearchLinks = import 'elasticsearch_links.libsonnet';
local issueSearch = import 'issue_search.libsonnet';

local selector = 'environment="$environment", type="sidekiq", stage="$stage", queue=~"$queue"';

local joinSelectors(selectors) =
  local nonEmptySelectors = std.filter(function(x) std.length(x) > 0, selectors);
  std.join(', ', nonEmptySelectors);

local latencyHistogramQuery(percentile, bucketMetric, selector, aggregator, rangeInterval) =
  local aggregatorWithLe = joinSelectors([aggregator] + ['le']);
  |||
    histogram_quantile(%(percentile)g, sum by (%(aggregatorWithLe)s) (
      rate(%(bucketMetric)s{%(selector)s}[%(rangeInterval)s])
    ))
  ||| % {
    percentile: percentile,
    aggregatorWithLe: aggregatorWithLe,
    selector: selector,
    bucketMetric: bucketMetric,
    rangeInterval: rangeInterval,
  };

local counterRateQuery(bucketMetric, selector, aggregator, rangeInterval) =
  |||
    sum by (%(aggregator)s) (
      rate(%(bucketMetric)s{%(selector)s}[%(rangeInterval)s])
    )
  ||| % {
    aggregator: aggregator,
    selector: selector,
    bucketMetric: bucketMetric,
    rangeInterval: rangeInterval,
  };

local counterChangesQuery(bucketMetric, selector, aggregator, rangeInterval) =
  |||
    sum by (%(aggregator)s) (
      changes(%(bucketMetric)s{%(selector)s}[%(rangeInterval)s])
    )
  ||| % {
    aggregator: aggregator,
    selector: selector,
    bucketMetric: bucketMetric,
    rangeInterval: rangeInterval,
  };

local queuelatencyTimeseries(title, aggregators, legendFormat) =
  basic.latencyTimeseries(
    title=title,
    query=latencyHistogramQuery(0.95, 'sidekiq_jobs_queue_duration_seconds_bucket', selector, aggregators, '$__interval'),
    legendFormat=legendFormat,
  );


local latencyTimeseries(title, aggregators, legendFormat) =
  basic.latencyTimeseries(
    title=title,
    query=latencyHistogramQuery(0.95, 'sidekiq_jobs_completion_seconds_bucket', selector, aggregators, '$__interval'),
    legendFormat=legendFormat,
  );

local enqueueRateTimeseries(title, aggregators, legendFormat) =
  basic.timeseries(
    title=title,
    query=counterRateQuery('sidekiq_enqueued_jobs_total', 'environment="$environment", queue=~"$queue"', aggregators, '$__interval'),
    legendFormat=legendFormat,
  );

local rpsTimeseries(title, aggregators, legendFormat) =
  basic.timeseries(
    title=title,
    query=counterRateQuery('sidekiq_jobs_completion_seconds_count', selector, aggregators, '$__interval'),
    legendFormat=legendFormat,
  );

local errorRateTimeseries(title, aggregators, legendFormat) =
  basic.timeseries(
    title=title,
    query=counterChangesQuery('sidekiq_jobs_failed_total', selector, aggregators, '$__interval'),
    legendFormat=legendFormat,
  );

local multiQuantileTimeseries(title, bucketMetric, aggregators) =
  local queries = std.map(
    function(p) {
      query: latencyHistogramQuery(p / 100, bucketMetric, selector, aggregators, '$__interval'),
      legendFormat: '{{ queue }} p%s' % [p],
    },
    [50, 90, 95, 99]
  );

  basic.multiTimeseries(title=title, decimals=2, queries=queries, yAxisLabel='Duration', format='s');

local statPanel(
  title,
  panelTitle,
  color,
  query,
  legendFormat,
      ) =
  {
    links: [],
    options: {
      graphMode: 'none',
      colorMode: 'background',
      justifyMode: 'auto',
      fieldOptions: {
        values: false,
        calcs: [
          'lastNotNull',
        ],
        defaults: {
          thresholds: {
            mode: 'absolute',
            steps: [
              {
                color: color,
                value: null,
              },
            ],
          },
          mappings: [],
          title: title,
          unit: 's',
          decimals: 0,
        },
        overrides: [],
      },
      orientation: 'vertical',
    },
    pluginVersion: '6.6.1',
    targets: [promQuery.target(query, legendFormat=legendFormat, instant=true)],
    title: panelTitle,
    type: 'stat',
  };

local elasticFilters = [
  elasticsearchLinks.matchFilter('json.queue.keyword', '$queue'),
  elasticsearchLinks.matchFilter('json.stage.keyword', '$stage'),
];

local elasticsearchLogSearchDataLink = {
  url: elasticsearchLinks.buildElasticDiscoverSearchQueryURL('sidekiq', elasticFilters),
  title: 'ElasticSearch: Sidekiq logs',
  targetBlank: true,
};

local rowGrid(rowTitle, panels, startRow) =
  [
    row.new(title=rowTitle) { gridPos: { x: 0, y: startRow, w: 24, h: 1 } },
  ] +
  layout.grid(panels, cols=std.length(panels), startRow=startRow + 1);

basic.dashboard(
  'Queue Detail',
  tags=['type:sidekiq', 'detail'],
)
.addTemplate(templates.stage)
.addTemplate(template.new(
  'queue',
  '$PROMETHEUS_DS',
  'label_values(sidekiq_jobs_completion_seconds_count{environment="$environment", type="sidekiq"}, queue)',
  current='post_receive',
  refresh='load',
  sort=1,
  multi=true,
  includeAll=true,
  allValues='.*',
))
.addPanels(
  layout.grid([
    basic.labelStat(
      query=|||
        label_replace(
          topk by (queue) (1, sum(rate(sidekiq_running_jobs{environment="$environment", type="sidekiq", stage="$stage", queue=~"$queue"}[$__range])) by (queue, %(label)s)),
          "%(label)s", "%(default)s", "%(label)s", ""
        )
      ||| % {
        label: attribute.label,
        default: attribute.default,
      },
      title=attribute.title,
      panelTitle='Queue Attribute: ' + attribute.title,
      color=attribute.color,
      legendFormat='{{ %s }} ({{ queue }})' % [attribute.label],
      links=attribute.links
    )
    for attribute in [{
      label: 'urgency',
      title: 'Urgency',
      color: 'yellow',
      default: 'unknown',
      links: [],
    }, {
      label: 'feature_category',
      title: 'Feature Category',
      color: 'blue',
      default: 'unknown',
      links: [],
    }, {
      label: 'priority',
      title: 'Priority',
      color: 'orange',
      default: 'unknown',
      links: [{
        title: 'Sidekiq Priority Detail: ${__field.labels.priority}',
        url: '/d/sidekiq-priority-detail/sidekiq-priority-detail?orgId=1&var-priority=${__field.labels.priority}&var-environment=${environment}&var-stage=${stage}&${__url_time_range}',
      }],
    }, {
      label: 'external_dependencies',
      title: 'External Dependencies',
      color: 'green',
      default: 'none',
      links: [],
    }, {
      label: 'boundary',
      title: 'Resource Boundary',
      color: 'purple',
      default: 'none',
      links: [],
    }]
  ] + [
    statPanel(
      'Max Queuing Duration SLO',
      'Max Queuing Duration SLO',
      'light-red',
      |||
        vector(%(nonUrgentSLO)f) and on () sidekiq_running_jobs{environment="$environment", type="sidekiq", stage="$stage", queue=~"$queue", urgency!="high"}
        or
        vector(%(urgentSLO)f) and on () sidekiq_running_jobs{environment="$environment", type="sidekiq", stage="$stage", queue=~"$queue", urgency="high"}
      ||| % {
        nonUrgentSLO: sidekiqHelpers.slos.nonUrgent.queueingDurationSeconds,
        urgentSLO: sidekiqHelpers.slos.urgent.queueingDurationSeconds,
      },
      '{{ queue }}',
    ),
    statPanel(
      'Max Execution Duration SLO',
      'Max Execution Duration SLO',
      'red',
      |||
        vector(%(nonUrgentSLO)f) and on () sidekiq_running_jobs{environment="$environment", type="sidekiq", stage="$stage", queue=~"$queue", urgency!="high"}
        or
        vector(%(urgentSLO)f) and on () sidekiq_running_jobs{environment="$environment", type="sidekiq", stage="$stage", queue=~"$queue", urgency="high"}
      ||| % {
        nonUrgentSLO: sidekiqHelpers.slos.nonUrgent.executionDurationSeconds,
        urgentSLO: sidekiqHelpers.slos.urgent.executionDurationSeconds,
      },
      '{{ queue }}',
    ),
  ], cols=8, rowHeight=4)
  +
  [row.new(title='🌡 Queue Key Metrics') { gridPos: { x: 0, y: 100, w: 24, h: 1 } }]
  +
  layout.grid([
    basic.apdexTimeseries(
      title='Queue Apdex',
      description='Queue apdex monitors the percentage of jobs that are dequeued within their queue threshold. Higher is better. Different jobs have different thresholds.',
      query=|||
        gitlab_background_jobs:queue:apdex:ratio_5m{environment="$environment", queue="$queue"}
      |||,
      yAxisLabel='% Jobs within Max Queuing Duration SLO',
      legendFormat='{{ queue }} queue apdex',
      legend_show=true,
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('/.* queue apdex$/'))
    .addDataLink(elasticsearchLogSearchDataLink)
    .addDataLink({
      url: elasticsearchLinks.buildElasticLinePercentileVizURL('sidekiq', elasticFilters, 'json.scheduling_latency_s'),
      title: 'ElasticSearch: queue latency visualization',
      targetBlank: true,
    }),
    basic.apdexTimeseries(
      title='Execution Apdex',
      description='Execution apdex monitors the percentage of jobs that run within their execution (run-time) threshold. Higher is better. Different jobs have different thresholds.',
      query=|||
        gitlab_background_jobs:execution:apdex:ratio_5m{environment="$environment", queue="$queue"}
      |||,
      yAxisLabel='% Jobs within Max Execution Duration SLO',
      legendFormat='{{ queue }} execution apdex',
      legend_show=true,
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('/.* execution apdex$/'))
    .addDataLink(elasticsearchLogSearchDataLink)
    .addDataLink({
      url: elasticsearchLinks.buildElasticLinePercentileVizURL('sidekiq', elasticFilters, 'json.duration'),
      title: 'ElasticSearch: execution latency visualization',
      targetBlank: true,
    }),

    basic.timeseries(
      title='Execution Rate (RPS)',
      description='Jobs executed per second',
      query=|||
        gitlab_background_jobs:execution:ops:rate_5m{environment="$environment", queue="$queue"}
      |||,
      legendFormat='{{ queue }} rps',
      format='ops',
      yAxisLabel='Jobs per Second',
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('/.* rps$/'))
    .addDataLink(elasticsearchLogSearchDataLink)
    .addDataLink({
      url: elasticsearchLinks.buildElasticLineCountVizURL('sidekiq', elasticFilters),
      title: 'ElasticSearch: RPS visualization',
      targetBlank: true,
    }),

    basic.percentageTimeseries(
      'Error Ratio',
      description='Percentage of jobs that fail with an error. Lower is better.',
      query=|||
        gitlab_background_jobs:execution:error:ratio_5m{environment="$environment", queue="$queue"}
      |||,
      legendFormat='{{ queue }} error ratio',
      yAxisLabel='Error Percentage',
      legend_show=true,
      decimals=2,
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('/.* error ratio$/'))
    .addDataLink(elasticsearchLogSearchDataLink)
    .addDataLink({
      url: elasticsearchLinks.buildElasticLineCountVizURL('sidekiq', elasticFilters + [elasticsearchLinks.matchFilter('json.job_status', 'fail')]),
      title: 'ElasticSearch: errors visualization',
      targetBlank: true,
    }),
  ], cols=4, rowHeight=8, startRow=101)
  +
  rowGrid('Enqueuing (the rate at which jobs are enqueued)', [
    enqueueRateTimeseries('Enqueues/Second', aggregators='queue', legendFormat='{{ queue }}'),
    enqueueRateTimeseries('Enqueues/Second per Service', aggregators='type, queue', legendFormat='{{ queue }} - {{ type }}'),
    basic.queueLengthTimeseries(
      title='Queue depth',
      description='The number of unstarted jobs in a queue',
      query=|||
        max by (name) (max_over_time(sidekiq_queue_size{environment="$environment", name=~"$queue"}[$__interval]) and on(fqdn) (redis_connected_slaves != 0))
      |||,
      legendFormat='{{ name }}',
      format='short',
      interval='1m',
      intervalFactor=3,
      yAxisLabel='',
    ),
  ], startRow=201)
  +
  rowGrid('Queue Latency (the amount of time spent queueing)', [
    queuelatencyTimeseries('Queue Time', aggregators='queue', legendFormat='p95 {{ queue }}'),
    queuelatencyTimeseries('Queue Time per Node', aggregators='fqdn, queue', legendFormat='p95 {{ queue }} - {{ fqdn }}'),
  ], startRow=301)
  +
  rowGrid('Execution Latency (the amount of time the job takes to execution after dequeue)', [
    latencyTimeseries('Execution Time', aggregators='queue', legendFormat='p95 {{ queue }}'),
    latencyTimeseries('Execution Time per Node', aggregators='fqdn, queue', legendFormat='p95 {{ queue }} - {{ fqdn }}'),
  ], startRow=401)
  +
  rowGrid('Execution RPS (the rate at which jobs are completed after dequeue)', [
    rpsTimeseries('RPS', aggregators='queue', legendFormat='{{ queue }}'),
    rpsTimeseries('RPS per Node', aggregators='fqdn, queue', legendFormat='{{ queue }} - {{ fqdn }}'),
  ], startRow=501)
  +
  rowGrid('Error Rate (the rate at which jobs fail)', [
    errorRateTimeseries('Error Rate', aggregators='queue', legendFormat='{{ queue }}'),
    errorRateTimeseries('Error Rate per Node', aggregators='fqdn, queue', legendFormat='{{ queue }} - {{ fqdn }}'),
  ], startRow=601)
  +
  rowGrid('Resource Usage', [
    multiQuantileTimeseries('CPU Time', bucketMetric='sidekiq_jobs_cpu_seconds_bucket', aggregators='queue'),
    multiQuantileTimeseries('Gitaly Time', bucketMetric='sidekiq_jobs_gitaly_seconds_bucket', aggregators='queue'),
    multiQuantileTimeseries('Database Time', bucketMetric='sidekiq_jobs_db_seconds_bucket', aggregators='queue'),
  ], startRow=701)
)
.trailer()
+ {
  links+:
    platformLinks.triage +
    serviceCatalog.getServiceLinks('sidekiq') +
    platformLinks.services +
    [
      platformLinks.dynamicLinks('Sidekiq Detail', 'type:sidekiq'),
      link.dashboards(
        'Find issues for $queue',
        '',
        type='link',
        targetBlank=true,
        url=issueSearch.buildInfraIssueSearch(labels=['Service::Sidekiq'], search='$queue')
      ),
    ],
}

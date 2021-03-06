local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local commonAnnotations = import 'grafana/common_annotations.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local dashboard = grafana.dashboard;
local link = grafana.link;
local template = grafana.template;
local annotation = grafana.annotation;
local serviceCatalog = import 'service_catalog.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local sidekiqHelpers = import 'services/lib/sidekiq-helpers.libsonnet';
local seriesOverrides = import 'grafana/series_overrides.libsonnet';
local row = grafana.row;
local elasticsearchLinks = import 'elasticlinkbuilder/elasticsearch_links.libsonnet';
local issueSearch = import 'issue_search.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

local selector = {
  environment: '$environment',
  type: 'sidekiq',
  stage: '$stage',
  queue: { re: '$queue' },
};

local recordingRuleLatencyHistogramQuery(percentile, recordingRule, selector, aggregator) =
  |||
    histogram_quantile(%(percentile)g, sum by (%(aggregator)s, le) (
      %(recordingRule)s{%(selector)s}
    ))
  ||| % {
    percentile: percentile,
    aggregator: aggregator,
    selector: selectors.serializeHash(selector),
    recordingRule: recordingRule,
  };

local recordingRuleRateQuery(recordingRule, selector, aggregator) =
  |||
    sum by (%(aggregator)s) (
      %(recordingRule)s{%(selector)s}
    )
  ||| % {
    aggregator: aggregator,
    selector: selectors.serializeHash(selector),
    recordingRule: recordingRule,
  };

local queuelatencyTimeseries(title, aggregators, legendFormat) =
  basic.latencyTimeseries(
    title=title,
    query=recordingRuleLatencyHistogramQuery(0.95, 'sli_aggregations:sidekiq_jobs_queue_duration_seconds_bucket_rate5m', selector, aggregators),
    legendFormat=legendFormat,
  );


local latencyTimeseries(title, aggregators, legendFormat) =
  basic.latencyTimeseries(
    title=title,
    query=recordingRuleLatencyHistogramQuery(0.95, 'sli_aggregations:sidekiq_jobs_queue_duration_seconds_bucket_rate5m', selector, aggregators),
    legendFormat=legendFormat,
  );

local enqueueCountTimeseries(title, aggregators, legendFormat) =
  basic.timeseries(
    title=title,
    query=recordingRuleRateQuery('gitlab_background_jobs:queue:ops:rate_5m', 'environment="$environment", queue=~"$queue"', aggregators),
    legendFormat=legendFormat,
  );

local rpsTimeseries(title, aggregators, legendFormat) =
  basic.timeseries(
    title=title,
    query=recordingRuleRateQuery('gitlab_background_jobs:execution:ops:rate_5m', 'environment="$environment", queue=~"$queue"', aggregators),
    legendFormat=legendFormat,
  );

local errorRateTimeseries(title, aggregators, legendFormat) =
  basic.timeseries(
    title=title,
    query=recordingRuleRateQuery('gitlab_background_jobs:execution:error:rate_5m', 'environment="$environment", queue=~"$queue"', aggregators),
    legendFormat=legendFormat,
  );

local elasticFilters = [elasticsearchLinks.matchFilter('json.stage.keyword', '$stage')];
local elasticQueries = ['json.queue.keyword:${queue:lucene}'];

local elasticsearchLogSearchDataLink = {
  url: elasticsearchLinks.buildElasticDiscoverSearchQueryURL('sidekiq', elasticFilters, elasticQueries),
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
      label: 'shard',
      title: 'Shard',
      color: 'orange',
      default: 'unknown',
      links: [{
        title: 'Sidekiq Shard Detail: ${__field.label.shard}',
        url: '/d/sidekiq-shard-detail/sidekiq-shard-detail?orgId=1&var-shard=${__field.label.shard}&var-environment=${environment}&var-stage=${stage}&${__url_time_range}',
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
    basic.statPanel(
      'Max Queuing Duration SLO',
      'Max Queuing Duration SLO',
      'light-red',
      |||
        vector(NaN) and on () sidekiq_running_jobs{environment="$environment", type="sidekiq", stage="$stage", queue=~"$queue", urgency="throttled"}
        or
        vector(%(lowUrgencySLO)f) and on () sidekiq_running_jobs{environment="$environment", type="sidekiq", stage="$stage", queue=~"$queue", urgency="low"}
        or
        vector(%(urgentSLO)f) and on () sidekiq_running_jobs{environment="$environment", type="sidekiq", stage="$stage", queue=~"$queue", urgency="high"}
      ||| % {
        lowUrgencySLO: sidekiqHelpers.slos.lowUrgency.queueingDurationSeconds,
        urgentSLO: sidekiqHelpers.slos.urgent.queueingDurationSeconds,
      },
      '{{ queue }}',
      unit='s',
    ),
    basic.statPanel(
      'Max Execution Duration SLO',
      'Max Execution Duration SLO',
      'red',
      |||
        vector(%(throttledSLO)f) and on () sidekiq_running_jobs{environment="$environment", type="sidekiq", stage="$stage", queue=~"$queue", urgency="throttled"}
        or
        vector(%(lowUrgencySLO)f) and on () sidekiq_running_jobs{environment="$environment", type="sidekiq", stage="$stage", queue=~"$queue", urgency="low"}
        or
        vector(%(urgentSLO)f) and on () sidekiq_running_jobs{environment="$environment", type="sidekiq", stage="$stage", queue=~"$queue", urgency="high"}
      ||| % {
        throttledSLO: sidekiqHelpers.slos.throttled.executionDurationSeconds,
        lowUrgencySLO: sidekiqHelpers.slos.lowUrgency.executionDurationSeconds,
        urgentSLO: sidekiqHelpers.slos.urgent.executionDurationSeconds,
      },
      '{{ queue }}',
      unit='s',
    ),
    basic.statPanel(
      'Time until backlog is cleared',
      'Backlog',
      'blue',
      |||
        ((sidekiq_queue_size{environment="$environment", name=~"$queue"} and on(fqdn) (redis_connected_slaves != 0)) > 10)
        /
        (-deriv(sidekiq_queue_size{environment="$environment", name=~"$queue"}[5m]) and on(fqdn) (redis_connected_slaves != 0) > 0)
      |||,
      '{{ name }}',
      unit='s',
    ),
  ], cols=8, rowHeight=4)
  +
  [row.new(title='🌡 Queue Key Metrics') { gridPos: { x: 0, y: 100, w: 24, h: 1 } }]
  +
  layout.grid([
    basic.apdexTimeseries(
      stableId='queue-apdex',
      title='Queue Apdex',
      description='Queue apdex monitors the percentage of jobs that are dequeued within their queue threshold. Higher is better. Different jobs have different thresholds.',
      query=|||
        sum by (queue) (
          (gitlab_background_jobs:queue:apdex:ratio_5m{environment="$environment", queue=~"$queue"} >= 0)
          *
          (gitlab_background_jobs:queue:apdex:weight:score_5m{environment="$environment", queue=~"$queue"} >= 0)
        )
        /
        sum by (queue) (
          (gitlab_background_jobs:queue:apdex:weight:score_5m{environment="$environment", queue=~"$queue"})
        )
      |||,
      yAxisLabel='% Jobs within Max Queuing Duration SLO',
      legendFormat='{{ queue }} queue apdex',
      legend_show=true,
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('/.* queue apdex$/'))
    .addDataLink(elasticsearchLogSearchDataLink)
    .addDataLink({
      url: elasticsearchLinks.buildElasticLinePercentileVizURL('sidekiq', elasticFilters, elasticQueries, 'json.scheduling_latency_s'),
      title: 'ElasticSearch: queue latency visualization',
      targetBlank: true,
    }),
    basic.apdexTimeseries(
      stableId='execution-apdex',
      title='Execution Apdex',
      description='Execution apdex monitors the percentage of jobs that run within their execution (run-time) threshold. Higher is better. Different jobs have different thresholds.',
      query=|||
        sum by (queue) (
          (gitlab_background_jobs:execution:apdex:ratio_5m{environment="$environment", queue=~"$queue"} >= 0)
          *
          (gitlab_background_jobs:execution:apdex:weight:score_5m{environment="$environment", queue=~"$queue"} >= 0)
        )
        /
        sum by (queue) (
          (gitlab_background_jobs:execution:apdex:weight:score_5m{environment="$environment", queue=~"$queue"})
        )
      |||,
      yAxisLabel='% Jobs within Max Execution Duration SLO',
      legendFormat='{{ queue }} execution apdex',
      legend_show=true,
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('/.* execution apdex$/'))
    .addDataLink(elasticsearchLogSearchDataLink)
    .addDataLink({
      url: elasticsearchLinks.buildElasticLinePercentileVizURL('sidekiq', elasticFilters, elasticQueries, 'json.duration_s'),
      title: 'ElasticSearch: execution latency visualization',
      targetBlank: true,
    }),

    basic.timeseries(
      stableId='request-rate',
      title='Execution Rate (RPS)',
      description='Jobs executed per second',
      query=|||
        sum by (queue) (gitlab_background_jobs:execution:ops:rate_5m{environment="$environment", queue=~"$queue"})
      |||,
      legendFormat='{{ queue }} rps',
      format='ops',
      yAxisLabel='Jobs per Second',
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('/.* rps$/'))
    .addDataLink(elasticsearchLogSearchDataLink)
    .addDataLink({
      url: elasticsearchLinks.buildElasticLineCountVizURL('sidekiq', elasticFilters, elasticQueries),
      title: 'ElasticSearch: RPS visualization',
      targetBlank: true,
    }),

    basic.percentageTimeseries(
      stableId='error-ratio',
      title='Error Ratio',
      description='Percentage of jobs that fail with an error. Lower is better.',
      query=|||
        sum by (queue) (
          (gitlab_background_jobs:execution:error:rate_5m{environment="$environment", queue=~"$queue"} >= 0)
        )
        /
        sum by (queue) (
          (gitlab_background_jobs:execution:ops:rate_5m{environment="$environment", queue=~"$queue"} >= 0)
        )
      |||,
      legendFormat='{{ queue }} error ratio',
      yAxisLabel='Error Percentage',
      legend_show=true,
      decimals=2,
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('/.* error ratio$/'))
    .addDataLink(elasticsearchLogSearchDataLink)
    .addDataLink({
      url: elasticsearchLinks.buildElasticLineCountVizURL(
        'sidekiq',
        elasticFilters + [elasticsearchLinks.matchFilter('json.job_status', 'fail')],
        elasticQueries
      ),
      title: 'ElasticSearch: errors visualization',
      targetBlank: true,
    }),
  ], cols=4, rowHeight=8, startRow=101)
  +
  rowGrid('Enqueuing (rate of jobs enqueuing)', [
    enqueueCountTimeseries('Jobs Enqueued', aggregators='queue', legendFormat='{{ queue }}'),
    enqueueCountTimeseries('Jobs Enqueued per Service', aggregators='type, queue', legendFormat='{{ queue }} - {{ type }}'),
    basic.queueLengthTimeseries(
      stableId='queue-length',
      title='Queue length',
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
    errorRateTimeseries('Errors', aggregators='queue', legendFormat='{{ queue }}'),
    errorRateTimeseries('Errors per Node', aggregators='fqdn, queue', legendFormat='{{ queue }} - {{ fqdn }}'),
  ], startRow=601)
  +
  [
    row.new(title='Resource Usage') { gridPos: { x: 0, y: 701, w: 24, h: 1 } },
  ] +
  layout.grid(
    [
      basic.multiQuantileTimeseries('CPU Time', selector, '{{ queue }}', bucketMetric='sidekiq_jobs_cpu_seconds_bucket', aggregators='queue'),
      basic.multiQuantileTimeseries('Gitaly Time', selector, '{{ queue }}', bucketMetric='sidekiq_jobs_gitaly_seconds_bucket', aggregators='queue'),
      basic.multiQuantileTimeseries('Database Time', selector, '{{ queue }}', bucketMetric='sidekiq_jobs_db_seconds_bucket', aggregators='queue'),
    ], cols=3, startRow=702
  )
  +
  layout.grid(
    [
      basic.multiQuantileTimeseries('Redis Time', selector, '{{ queue }}', bucketMetric='sidekiq_redis_requests_duration_seconds_bucket', aggregators='queue'),
      basic.multiQuantileTimeseries('Elasticsearch Time', selector, '{{ queue }}', bucketMetric='sidekiq_elasticsearch_requests_duration_seconds_bucket', aggregators='queue'),
    ], cols=3, startRow=703
  )
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

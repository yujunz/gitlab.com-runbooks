local basic = import 'basic.libsonnet';
local capacityPlanning = import 'capacity_planning.libsonnet';
local colors = import 'colors.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local layout = import 'layout.libsonnet';
local nodeMetrics = import 'node_metrics.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local railsCommon = import 'rails_common_graphs.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local sidekiq = import 'sidekiq.libsonnet';
local saturationDetail = import 'saturation_detail.libsonnet';
local thresholds = import 'thresholds.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local link = grafana.link;
local elasticsearchLinks = import 'elasticsearch_links.libsonnet';

local optimalUtilization = 0.33;
local optimalMargin = 0.10;

local selector = 'type="sidekiq", environment="$environment", stage="$stage", priority=~"$priority"';

local queueDetailDataLink = {
  url: '/d/sidekiq-queue-detail?${__url_time_range}&${__all_variables}&var-queue=${__field.labels.queue}',
  title: 'Queue Detail: ${__field.labels.queue}',
};

local rowGrid(rowTitle, panels, startRow) =
  [
    row.new(title=rowTitle) { gridPos: { x: 0, y: startRow, w: 24, h: 1 } },
  ] +
  layout.grid(panels, cols=std.length(panels), startRow=startRow + 1);

local queueTimeLatencyTimeseries(title, aggregator) =
  basic.latencyTimeseries(
    title=title,
    description='Estimated queue time, between when the job is enqueued and executed. Lower is better.',
    query=|||
      histogram_quantile(0.95, sum(rate(sidekiq_jobs_queue_duration_seconds_bucket{environment="$environment", priority=~"$priority"}[$__interval])) by (le, %s))
    ||| % [aggregator],
    legendFormat='{{ %s }}' % [aggregator],
    format='s',
    yAxisLabel='Queue Duration',
    interval='1m',
    intervalFactor=3,
    legend_show=true,
    logBase=10,
    linewidth=1,
    min=0.01,
  );

local inflightJobsTimeseries(title, aggregator) =
  basic.timeseries(
    title=title,
    description='The total number of jobs being executed at a single moment for the priority',
    query=|||
      sum(sidekiq_running_jobs{environment="$environment", priority=~"$priority"}) by (%s)
    ||| % [aggregator],
    legendFormat='{{ %s }}' % [aggregator],
    interval='1m',
    intervalFactor=1,
    legend_show=true,
    linewidth=1,
  );

basic.dashboard(
  'Priority Detail',
  tags=['type:sidekiq', 'detail'],
)
.addTemplate(templates.stage)
.addTemplate(template.new(
  'priority',
  '$PROMETHEUS_DS',
  'label_values(up{environment="$environment", type="sidekiq", job="gitlab-sidekiq"}, priority)',
  current='besteffort',
  refresh='load',
  sort=1,
  multi=true,
  includeAll=true,
  allValues='.*',
))
.addPanels(
  rowGrid('Queue Time - time spend queueing', [
    queueTimeLatencyTimeseries(
      title='Sidekiq Estimated p95 Job Queue Time for $priority priority',
      aggregator='priority'
    ),
    queueTimeLatencyTimeseries(
      title='Sidekiq Estimated p95 Job Queue Time per Queue, $priority priority',
      aggregator='queue'
    )
    .addDataLink(queueDetailDataLink),
  ], startRow=101)
  +
  rowGrid('Inflight Jobs - jobs currently running', [
    inflightJobsTimeseries(
      title='Sidekiq Inflight Jobs for $priority priority',
      aggregator='priority'
    ),
    inflightJobsTimeseries(
      title='Sidekiq Inflight Jobs per Queue, $priority priority',
      aggregator='queue'
    )
    .addDataLink(queueDetailDataLink),
  ], startRow=201)
  +
  rowGrid('Individual Execution Time - time taken for individual jobs to complete', [
    basic.multiTimeseries(
      title='Sidekiq Estimated Median Job Latency for $priority priority',
      description='The median duration, once a job starts executing, that it runs for, by priority. Lower is better.',
      queries=[
        {
          query: |||
            histogram_quantile(0.50,
              sum by (priority, le) (
                rate(sidekiq_jobs_completion_seconds_bucket{
                  environment="$environment",
                  priority=~"$priority"
                }[$__interval])
              )
            )
          |||,
          legendFormat: '{{ priority }} p50',
        },
        {
          query: |||
            histogram_quantile(0.95,
              sum by (priority, le) (
                rate(sidekiq_jobs_completion_seconds_bucket{
                  environment="$environment",
                  priority=~"$priority"
                }[$__interval])
              )
            )
          |||,
          legendFormat: '{{ priority }} p95',
        },
      ],
      format='s',
      yAxisLabel='Duration',
      interval='1m',
      intervalFactor=3,
      legend_show=true,
      linewidth=1,
    ),
    basic.latencyTimeseries(
      title='Sidekiq Estimated p95 Job Latency per Queue, for $priority priority',
      description='The 95th percentile duration, once a job starts executing, that it runs for, by priority. Lower is better.',
      query=|||
        histogram_quantile(0.95,
          sum by (queue, le) (
            rate(sidekiq_jobs_completion_seconds_bucket{
              environment="$environment",
              priority=~"$priority"
            }[$__interval])
          )
        )
      |||,
      legendFormat='p95 {{ queue }}',
      format='s',
      yAxisLabel='Duration',
      interval='2m',
      intervalFactor=5,
      legend_show=true,
      logBase=10,
      linewidth=1,
    ),
  ], startRow=301)
  +
  rowGrid('Total Execution Time - total time consumed processing jobs', [
    basic.timeseries(
      title='Sidekiq Total Execution Time for $priority Priority',
      description='The sum of job execution times',
      query=|||
        sum(rate(sidekiq_jobs_completion_seconds_sum{environment="$environment", priority=~"$priority"}[$__interval])) by (priority)
      |||,
      legendFormat='{{ priority }}',
      interval='1m',
      format='s',
      intervalFactor=1,
      legend_show=true,
      yAxisLabel='Job time completed per second',
    ),
  ], startRow=401)
  +
  rowGrid('Throughput - rate at which jobs complete', [
    basic.timeseries(
      title='Sidekiq Aggregated Throughput for $priority Priority',
      description='The total number of jobs being completed',
      query=|||
        sum(queue:sidekiq_jobs_completion:rate1m{environment="$environment", priority=~"$priority"}) by (priority)
      |||,
      legendFormat='{{ priority }}',
      interval='1m',
      intervalFactor=1,
      legend_show=true,
      yAxisLabel='Jobs Completed per Second',
    ),
    basic.timeseries(
      title='Sidekiq Throughput per Queue for $priority Priority',
      description='The total number of jobs being completed per queue for priority',
      query=|||
        sum(queue:sidekiq_jobs_completion:rate1m{environment="$environment", priority=~"$priority"}) by (queue)
      |||,
      legendFormat='{{ queue }}',
      interval='1m',
      intervalFactor=1,
      linewidth=1,
      legend_show=true,
      yAxisLabel='Jobs Completed per Second',
    )
    .addDataLink(queueDetailDataLink),
  ], startRow=501)
  +
  rowGrid('Utilization - saturation of workers in this fleet', [
    basic.percentageTimeseries(
      'Priority Utilization',
      description='How heavily utilized is this priority? Ideally this should be around 33% plus minus 10%. If outside this range for long periods, consider scaling fleet appropriately.',
      query=|||
        sum by (environment, stage, priority)  (rate(sidekiq_jobs_completion_seconds_sum{environment="$environment", priority=~"$priority"}[1h]))
        /
        sum by (environment, stage, priority)  (avg_over_time(sidekiq_concurrency{environment="$environment", priority=~"$priority"}[1h]))
      |||,
      legendFormat='{{ priority }} utilization (per hour)',
      yAxisLabel='Percent',
      interval='5m',
      intervalFactor=1,
      linewidth=2,
      max=1,
      thresholds=[
        thresholds.optimalLevel('gt', optimalUtilization - optimalMargin),
        thresholds.optimalLevel('lt', optimalUtilization + optimalMargin),
        thresholds.warningLevel('gt', optimalUtilization + optimalMargin),
      ]
    )
    .addTarget(
      promQuery.target(
        expr=|||
          sum by (environment, stage, priority)  (rate(sidekiq_jobs_completion_seconds_sum{environment="$environment", priority=~"$priority"}[10m]))
          /
          sum by (environment, stage, priority)  (avg_over_time(sidekiq_concurrency{environment="$environment", priority=~"$priority"}[10m]))
        |||,
        legendFormat='{{ priority }} utilization (per 10m)'
      )
    )
    .addTarget(
      promQuery.target(
        expr=|||
          sum by (environment, stage, priority)  (rate(sidekiq_jobs_completion_seconds_sum{environment="$environment", priority=~"$priority"}[$__interval]))
          /
          sum by (environment, stage, priority)  (avg_over_time(sidekiq_concurrency{environment="$environment", priority=~"$priority"}[$__interval]))
        |||,
        legendFormat='{{ priority }} utilization (instant)'
      )
    ),

  ], startRow=601)
)
.addPanel(
  row.new(title='Rails Metrics', collapse=true)
  .addPanels(railsCommon.railsPanels(serviceType='sidekiq', serviceStage='$stage', startRow=1))
  ,
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanel(nodeMetrics.nodeMetricsDetailRow(selector), gridPos={ x: 0, y: 4000 })
.addPanel(
  saturationDetail.saturationDetailPanels(selector, components=[
    'cpu',
    'disk_space',
    'memory',
    'open_fds',
    'sidekiq_workers',
    'single_node_cpu',
    'single_node_puma_workers',
    'single_node_unicorn_workers',
    'workers',
  ]),
  gridPos={ x: 0, y: 5000, w: 24, h: 1 }
)
+ {
  links+:
    platformLinks.triage +
    serviceCatalog.getServiceLinks('sidekiq') +
    platformLinks.services +
    [
      link.dashboards(
        'ELK $priority priority logs',
        '',
        type='link',
        targetBlank=true,
        url=elasticsearchLinks.buildElasticDiscoverSearchQueryURL(
          'sidekiq', [
            elasticsearchLinks.matchFilter('json.hostname', '$priority'),  // No priority label yet
            elasticsearchLinks.matchFilter('json.stage.keyword', '$stage'),
          ]
        ),
      ),
      link.dashboards(
        'ELK $priority priority ops/sec visualization',
        '',
        type='link',
        targetBlank=true,
        url=elasticsearchLinks.buildElasticLineCountVizURL(
          'sidekiq', [
            elasticsearchLinks.matchFilter('json.hostname', '$priority'),  // No priority label yet
            elasticsearchLinks.matchFilter('json.stage.keyword', '$stage'),
          ]
        ),
      ),
      link.dashboards(
        'ELK $priority priority latency visualization',
        '',
        type='link',
        targetBlank=true,
        url=elasticsearchLinks.buildElasticLinePercentileVizURL(
          'sidekiq',
          [
            elasticsearchLinks.matchFilter('json.hostname', '$priority'),  // No priority label yet
            elasticsearchLinks.matchFilter('json.stage.keyword', '$stage'),
          ],
          field='json.duration'
        ),
      ),
    ],
}

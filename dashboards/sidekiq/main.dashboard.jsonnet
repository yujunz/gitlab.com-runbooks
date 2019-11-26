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
local unicornCommon = import 'unicorn_common_graphs.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local sidekiq = import 'sidekiq.libsonnet';
local serviceHealth = import 'service_health.libsonnet';
local saturationDetail = import 'saturation_detail.libsonnet';
local metricsCatalogDashboards = import 'metrics_catalog_dashboards.libsonnet';

dashboard.new(
  'Overview',
  schemaVersion=16,
  tags=['type:sidekiq', 'overview'],
  timezone='utc',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addTemplate(templates.stage)
.addPanels(keyMetrics.headlineMetricsRow('sidekiq', '$stage', startRow=0))
.addPanel(serviceHealth.row('sidekiq', '$stage'), gridPos={ x: 0, y: 500 })
.addPanel(
  row.new(title='Sidekiq Queues'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.queueLengthTimeseries(
      title='Sidekiq Aggregated Queue Length',
      description='The total number of jobs in the system queued up to be executed. Lower is better.',
      query=|||
        sum(sidekiq_queue_size{environment="$environment"} and on(fqdn) (redis_connected_slaves != 0))
      |||,
      legendFormat='Total Jobs',
      format='short',
      interval='1m',
      intervalFactor=3,
      yAxisLabel='Queue Length',
    ),
    basic.queueLengthTimeseries(
      title='Sidekiq Queue Lengths per Queue',
      description='The number of jobs queued up to be executed. Lower is better',
      query=|||
        max_over_time(sidekiq_queue_size{environment="$environment"}[$__interval]) and on(fqdn) (redis_connected_slaves != 0)
      |||,
      legendFormat='{{ name }}',
      format='short',
      interval='1m',
      linewidth=1,
      intervalFactor=3,
      yAxisLabel='Queue Length',
    ),
    basic.latencyTimeseries(
      title='Sidekiq Queuing Latency per Job',
      description='The amount of time a job has to wait before it starts being executed. Lower is better.',
      query=|||
        avg_over_time(sidekiq_queue_latency[$__interval]) and on (fqdn) (redis_connected_slaves != 0)
      |||,
      legendFormat='{{ name }}',
      format='s',
      yAxisLabel='Duration',
      interval='1m',
      intervalFactor=3,
      legend_show=true,
      linewidth=1,
      min=0,
    ),
  ], cols=2, rowHeight=10, startRow=1001),
)
.addPanel(
  row.new(title='Sidekiq Execution'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Sidekiq Total Execution Time',
      description='The sum of job execution times',
      query=|||
        sum(rate(sidekiq_jobs_completion_seconds_sum{environment="$environment"}[$__interval]))
      |||,
      legendFormat='Total',
      interval='1m',
      format='s',
      intervalFactor=1,
      legend_show=true,
      yAxisLabel='Job time completed per second',
    ),
    basic.timeseries(
      title='Sidekiq Total Execution Time Per Priority',
      description='The sum of job execution times',
      query=|||
        sum(rate(sidekiq_jobs_completion_seconds_sum{environment="$environment"}[$__interval])) by (priority)
      |||,
      legendFormat='{{ priority }}',
      interval='1m',
      format='s',
      linewidth=1,
      intervalFactor=1,
      legend_show=true,
      yAxisLabel='Job time completed per second',
    ),
    basic.timeseries(
      title='Sidekiq Aggregated Throughput',
      description='The total number of jobs being completed',
      query=|||
        sum(queue:sidekiq_jobs_completion:rate1m{environment="$environment"})
      |||,
      legendFormat='Total',
      interval='1m',
      intervalFactor=1,
      legend_show=true,
      yAxisLabel='Jobs Completed per Second',
    ),
    basic.timeseries(
      title='Sidekiq Throughput per Priority',
      description='The total number of jobs being completed per priority',
      query=|||
        sum(queue:sidekiq_jobs_completion:rate1m{environment="$environment"}) by (priority)
      |||,
      legendFormat='{{ priority }}',
      interval='1m',
      linewidth=1,
      intervalFactor=1,
      legend_show=true,
      yAxisLabel='Jobs Completed per Second',
    ),
    basic.timeseries(
      title='Sidekiq Throughput per Job',
      description='The total number of jobs being completed per priority',
      query=|||
        sum(queue:sidekiq_jobs_completion:rate1m{environment="$environment"}) by (queue)
      |||,
      legendFormat='{{ queue }}',
      interval='1m',
      intervalFactor=1,
      linewidth=1,
      legend_show=true,
      yAxisLabel='Jobs Completed per Second',
    ),

    basic.timeseries(
      title='Sidekiq Aggregated Inflight Operations',
      description='The total number of jobs being executed at a single moment',
      query=|||
        sum(sidekiq_running_jobs_count{environment="$environment"} and on(fqdn) (redis_connected_slaves != 0))
      |||,
      legendFormat='Total',
      interval='1m',
      intervalFactor=1,
      legend_show=true,
    ),
    basic.timeseries(
      title='Sidekiq Inflight Operations by Queue',
      description='The total number of jobs being executed at a single moment, for each queue',
      query=|||
        sum(sidekiq_running_jobs_count{environment="$environment"} and on(fqdn) (redis_connected_slaves != 0)) by (name)
      |||,
      legendFormat='{{ name }}',
      interval='1m',
      intervalFactor=1,
      legend_show=true,
      linewidth=1,
    ),
    basic.latencyTimeseries(
      title='Sidekiq Estimated Median Job Latency per priority',
      description='The median duration, once a job starts executing, that it runs for, by priority. Lower is better.',
      query=|||
        avg(priority:sidekiq_jobs_completion_seconds:p50{environment="$environment"}) by (priority)
      |||,
      legendFormat='{{ priority }}',
      format='s',
      yAxisLabel='Duration',
      interval='1m',
      intervalFactor=3,
      legend_show=true,
      logBase=10,
      linewidth=1,
      min=0.01,
    ),
    basic.latencyTimeseries(
      title='Sidekiq Estimated p95 Job Latency per priority',
      description='The 95th percentile duration, once a job starts executing, that it runs for, by priority. Lower is better.',
      query=|||
        avg(priority:sidekiq_jobs_completion_seconds:p95{environment="$environment"}) by (priority)
      |||,
      legendFormat='{{ priority }}',
      format='s',
      yAxisLabel='Duration',
      interval='1m',
      intervalFactor=3,
      legend_show=true,
      logBase=10,
      linewidth=1,
      min=0.01,
    ),
  ], cols=2, rowHeight=10, startRow=2001),
)
.addPanel(
  row.new(title='Priority Workloads'),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanels(sidekiq.priorityWorkloads('type="sidekiq", environment="$environment", stage="$stage"', startRow=3001))
.addPanel(
  row.new(title='Unicorn Metrics', collapse=true)
  .addPanels(unicornCommon.unicornPanels(serviceType='sidekiq', serviceStage='$stage', startRow=1))
  ,
  gridPos={
    x: 0,
    y: 4000,
    w: 24,
    h: 1,
  }
)
.addPanel(
  row.new(title='Rails Metrics', collapse=true)
  .addPanels(railsCommon.railsPanels(serviceType='sidekiq', serviceStage='$stage', startRow=1))
  ,
  gridPos={
    x: 0,
    y: 5000,
    w: 24,
    h: 1,
  }
)
.addPanel(keyMetrics.keyServiceMetricsRow('sidekiq', '$stage'), gridPos={ x: 0, y: 6000 })
.addPanel(keyMetrics.keyComponentMetricsRow('sidekiq', '$stage'), gridPos={ x: 0, y: 7000 })
.addPanel(
  metricsCatalogDashboards.componentDetailMatrix(
    'sidekiq',
    'latency_sensitive_job_execution',
    'environment="$environment", type="sidekiq", stage="$stage"',
    [
      { title: 'Overall', aggregationLabels: '', legendFormat: 'latency_sensitive_job_execution' },
      { title: 'per Queue', aggregationLabels: 'queue', legendFormat: '{{ queue }}' },
    ],
  ), gridPos={ x: 0, y: 7100 }
)
.addPanel(
  metricsCatalogDashboards.componentDetailMatrix(
    'sidekiq',
    'latency_sensitive_job_queueing',
    'environment="$environment", type="sidekiq", stage="$stage"',
    [
      { title: 'Overall', aggregationLabels: '', legendFormat: 'latency_sensitive_job_queueing' },
      { title: 'per Queue', aggregationLabels: 'queue', legendFormat: '{{ queue }}' },
    ],
  ), gridPos={ x: 0, y: 7200 }
)
.addPanel(
  metricsCatalogDashboards.componentDetailMatrix(
    'sidekiq',
    'non_latency_sensitive_job_execution',
    'environment="$environment", type="sidekiq", stage="$stage"',
    [
      { title: 'Overall', aggregationLabels: '', legendFormat: 'non_latency_sensitive_job_execution' },
      { title: 'per Queue', aggregationLabels: 'queue', legendFormat: '{{ queue }}' },
    ],
  ), gridPos={ x: 0, y: 7300 }
)
.addPanel(
  metricsCatalogDashboards.componentDetailMatrix(
    'sidekiq',
    'non_latency_sensitive_job_queueing',
    'environment="$environment", type="sidekiq", stage="$stage"',
    [
      { title: 'Overall', aggregationLabels: '', legendFormat: 'non_latency_sensitive_job_queueing' },
      { title: 'per Queue', aggregationLabels: 'queue', legendFormat: '{{ queue }}' },
    ],
  ), gridPos={ x: 0, y: 7400 }
)

.addPanel(nodeMetrics.nodeMetricsDetailRow('type="sidekiq", environment="$environment", stage="$stage"'), gridPos={ x: 0, y: 8000 })
.addPanel(
  saturationDetail.saturationDetailPanels('sidekiq', '$stage', components=[
    'cpu',
    'disk_space',
    'memory',
    'open_fds',
    'sidekiq_workers',
    'single_node_cpu',
    'single_node_unicorn_workers',
    'workers',
  ]),
  gridPos={ x: 0, y: 9000, w: 24, h: 1 }
)
.addPanel(
  capacityPlanning.capacityPlanningRow('sidekiq', '$stage'), gridPos={ x: 0, y: 10000 }
)
+ {
  links+: platformLinks.triage +
          serviceCatalog.getServiceLinks('sidekiq') +
          platformLinks.services +
          [platformLinks.dynamicLinks('Sidekiq Detail', 'type:sidekiq')],
}

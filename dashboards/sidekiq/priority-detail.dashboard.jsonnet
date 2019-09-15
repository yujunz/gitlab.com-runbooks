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

dashboard.new(
  'Priority Detail',
  schemaVersion=16,
  tags=['type:sidekiq', 'detail'],
  timezone='utc',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addTemplate(templates.stage)
.addTemplate(template.new(
  "priority",
  "$PROMETHEUS_DS",
  'label_values(up{environment="$environment", type="sidekiq", job="gitlab-sidekiq"}, priority)',
  current="besteffort",
  refresh='load',
  sort=1,
  multi=true,
  includeAll=true,
  allValues='.*',
))
.addPanel(
row.new(title="Sidekiq Execution"),
  gridPos={
      x: 0,
      y: 1000,
      w: 24,
      h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title="Sidekiq Total Execution Time for Priority",
      description="The sum of job execution times",
      query='
        sum(rate(sidekiq_jobs_completion_time_seconds_sum{environment="$environment", priority=~"$priority"}[$__interval])) by (priority)
      ',
      legendFormat='{{ priority }}',
      interval="1m",
      format="s",
      intervalFactor=1,
      legend_show=true,
      yAxisLabel='Job time completed per second',
    ),
    basic.timeseries(
      title="Sidekiq Aggregated Throughput for Priority",
      description="The total number of jobs being completed",
      query='
        sum(worker:sidekiq_jobs_completion:rate1m{environment="$environment", priority=~"$priority"}) by (priority)
      ',
      legendFormat='{{ priority }}',
      interval="1m",
      intervalFactor=1,
      legend_show=true,
      yAxisLabel='Jobs Completed per Second',
    ),
    basic.timeseries(
      title="Sidekiq Throughput per Job for Priority",
      description="The total number of jobs being completed per priority",
      query='
        sum(worker:sidekiq_jobs_completion:rate1m{environment="$environment", priority=~"$priority"}) by (worker)
      ',
      legendFormat='{{ worker }}',
      interval="1m",
      intervalFactor=1,
      linewidth=1,
      legend_show=true,
      yAxisLabel='Jobs Completed per Second',
    ),
    basic.latencyTimeseries(
      title="Sidekiq Estimated Median Job Latency for priority",
      description="The median duration, once a job starts executing, that it runs for, by priority. Lower is better.",
      query='
        avg(priority:sidekiq_jobs_completion_time_seconds:p50{environment="$environment", priority=~"$priority"}) by (priority)
      ',
      legendFormat='{{ priority }}',
      format="s",
      yAxisLabel='Duration',
      interval="1m",
      intervalFactor=3,
      legend_show=true,
      logBase=10,
      linewidth=1,
      min=0.01,
    ),
    basic.latencyTimeseries(
      title="Sidekiq Estimated p95 Job Latency for priority",
      description="The 95th percentile duration, once a job starts executing, that it runs for, by priority. Lower is better.",
      query='
        avg(priority:sidekiq_jobs_completion_time_seconds:p95{environment="$environment", priority=~"$priority"}) by (priority)
      ',
      legendFormat='{{ priority }}',
      format="s",
      yAxisLabel='Duration',
      interval="1m",
      intervalFactor=3,
      legend_show=true,
      logBase=10,
      linewidth=1,
      min=0.01,
    ),
  ], cols=2, rowHeight=10, startRow=1001),
)
.addPanel(
row.new(title="Priority Workloads"),
  gridPos={
      x: 0,
      y: 2000,
      w: 24,
      h: 1,
  }
)
.addPanels(sidekiq.priorityWorkloads('type="sidekiq", environment="$environment", stage="$stage", priority=~"$priority"', startRow=2001))
.addPanel(
  row.new(title="Rails Metrics", collapse=true)
    .addPanels(railsCommon.railsPanels(serviceType="sidekiq", serviceStage="$stage", startRow=1))
  ,
  gridPos={
      x: 0,
      y: 3000,
      w: 24,
      h: 1,
  }
)
.addPanel(nodeMetrics.nodeMetricsDetailRow('type="sidekiq", environment="$environment", stage="$stage", priority=~"$priority"'), gridPos={ x: 0, y: 6000 })
.addPanel(capacityPlanning.capacityPlanningRow('sidekiq', '$stage'), gridPos={ x: 0, y: 7000 })
+ {
  links+: platformLinks.triage + serviceCatalog.getServiceLinks('sidekiq') + platformLinks.services,
}

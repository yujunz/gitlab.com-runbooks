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

dashboard.new(
  'Feature Flag: ci_composite_status',
  schemaVersion=16,
  tags=['type:sidekiq', 'feature-flag'],
  timezone='utc',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addTemplate(templates.stage)
.addPanels(
  layout.grid([
    basic.latencyTimeseries(
      title='PipelineProcessWorker, StageUpdateWorker median execution duration',
      query='\n        histogram_quantile(0.5, sum(rate(sidekiq_jobs_completion_time_seconds_bucket{environment="$environment", worker=~"PipelineProcessWorker|StageUpdateWorker"}[$__interval])) by (le, worker))\n      ',
      legendFormat='{{ worker }}',
      format='s',
      interval='5m',
      intervalFactor=1,
      legend_show=true,
    ),
    basic.latencyTimeseries(
      title='PipelineProcessWorker, StageUpdateWorker p95 execution duration (log 10 scale)',
      query='\n        histogram_quantile(0.95, sum(rate(sidekiq_jobs_completion_time_seconds_bucket{environment="$environment", worker=~"PipelineProcessWorker|StageUpdateWorker"}[$__interval])) by (le, worker))\n      ',
      legendFormat='{{ worker }}',
      format='s',
      legend_show=true,
      interval='5m',
      intervalFactor=1,
      logBase=10,
      min=0.001
    ),
  ], cols=1, rowHeight=10, startRow=1001),
)
.addPanel(nodeMetrics.nodeMetricsDetailRow('type="sidekiq", priority="pipeline", environment="$environment"'), gridPos={ x: 0, y: 7000 })
+ {
  links+: platformLinks.triage +
          serviceCatalog.getServiceLinks('sidekiq') +
          platformLinks.services +
          [platformLinks.dynamicLinks('Sidekiq Detail', 'type:sidekiq')],
}

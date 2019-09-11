local basic = import 'basic.libsonnet';
local colors = import 'colors.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local layout = import 'layout.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local seriesOverrides = import 'series_overrides.libsonnet';

local sidekiqWorkerLatency() = basic.latencyTimeseries(
    title="Worker Latency",
    description="${percentile}th percentile worker latency. Lower is better.",
    query='
      histogram_quantile($percentile/100, sum(rate(sidekiq_jobs_completion_time_seconds_bucket{environment="$environment", worker="$worker"}[$__interval])) by (le, environment, stage, tier, type, worker))
    ',
    legendFormat='{{ worker }}'
  )
  .addTarget(
    promQuery.target('$threshold', legendFormat='threshold')
  )
  .addSeriesOverride(seriesOverrides.thresholdSeries('threshold'));

dashboard.new(
  'Worker Apdex Violation Alert',
  schemaVersion=16,
  tags=['alert-target', 'sidekiq'],
  timezone='UTC',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addTemplate(templates.sidekiqWorker)
.addTemplate(
template.custom(
    "threshold",
    "0.025,0.05,0.1,0.25,0.5,1,2.5,5,10,25,50",
    "1",
  )
)
.addTemplate(
template.custom(
    "percentile",
    "50,80,90,95,99",
    "95",
  )
)
.addPanels(layout.grid([
    sidekiqWorkerLatency(),
  ], cols=1, rowHeight=10))
+ {
  links+: platformLinks.serviceLink('sidekiq') + platformLinks.triage,
}

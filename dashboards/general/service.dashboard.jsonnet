local capacityPlanning = import 'capacity_planning.libsonnet';
local colors = import 'colors.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local layout = import 'layout.libsonnet';
local nodeMetrics = import 'node_metrics.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local serviceHealth = import 'service_health.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local basic = import 'basic.libsonnet';

local generalGraphPanel(title, description=null, linewidth=2, sort='increasing') =
  graphPanel.new(
    title,
    linewidth=linewidth,
    fill=0,
    datasource='$PROMETHEUS_DS',
    description=description,
    decimals=2,
    sort=sort,
    legend_show=true,
    legend_values=true,
    legend_min=true,
    legend_max=true,
    legend_current=true,
    legend_total=false,
    legend_avg=true,
    legend_alignAsTable=true,
    legend_hideEmpty=true,
  )
  .addSeriesOverride(seriesOverrides.goldenMetric('/ service/'))
  .addSeriesOverride(seriesOverrides.upper)
  .addSeriesOverride(seriesOverrides.lower)
  .addSeriesOverride(seriesOverrides.upperLegacy)
  .addSeriesOverride(seriesOverrides.lowerLegacy)
  .addSeriesOverride(seriesOverrides.lastWeek)
  .addSeriesOverride(seriesOverrides.alertFiring)
  .addSeriesOverride(seriesOverrides.alertPending)
  .addSeriesOverride(seriesOverrides.degradationSlo)
  .addSeriesOverride(seriesOverrides.outageSlo)
  .addSeriesOverride(seriesOverrides.slo);

basic.dashboard(
  'Service Platform Metrics',
  tags=['general'],
)
.addTemplate(templates.type)
.addTemplate(templates.stage)
.addTemplate(templates.sigma)
.addPanel(serviceHealth.row('$type', '$stage'), gridPos={ x: 0, y: 0 })
.addPanel(
  row.new(title='🏅 Key Service Metrics'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    keyMetrics.apdexPanel('$type', '$stage'),
    keyMetrics.errorRatesPanel('$type', '$stage'),
    keyMetrics.qpsPanel('$type', '$stage'),
    keyMetrics.saturationPanel('$type', '$stage'),
  ], startRow=1001)
)
.addPanel(
  keyMetrics.keyComponentMetricsRow('$type', '$stage'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanel(
  nodeMetrics.nodeMetricsDetailRow('environment="$environment", stage=~"|$stage", type="$type"'),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanel(capacityPlanning.capacityPlanningRow('$type', '$stage'), gridPos={ x: 0, y: 4000 })

+ {
  links+: platformLinks.services + platformLinks.triage,
}

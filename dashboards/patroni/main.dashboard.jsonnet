local basic = import 'basic.libsonnet';
local capacityPlanning = import 'capacity_planning.libsonnet';
local colors = import 'colors.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local layout = import 'layout.libsonnet';
local nodeMetrics = import 'node_metrics.libsonnet';
local pgbouncerCommonGraphs = import 'pgbouncer_common_graphs.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local serviceHealth = import 'service_health.libsonnet';

dashboard.new(
  'Overview',
  schemaVersion=16,
  tags=['patroni'],
  timezone='utc',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addPanel(serviceHealth.row('patroni', '$stage'), gridPos={ x: 0, y: 0 })
.addPanel(
row.new(title="pgbouncer Workload", collapse=false),
  gridPos={
      x: 0,
      y: 1000,
      w: 24,
      h: 1,
  }
)
.addPanels(pgbouncerCommonGraphs.workloadStats('patroni', 1001))
.addPanel(
row.new(title="pgbouncer Connection Pooling", collapse=false),
  gridPos={
      x: 0,
      y: 2000,
      w: 24,
      h: 1,
  }
)
.addPanels(pgbouncerCommonGraphs.connectionPoolingPanels('patroni', 2001))
.addPanel(
row.new(title="pgbouncer Network", collapse=false),
  gridPos={
      x: 0,
      y: 3000,
      w: 24,
      h: 1,
  }
)
.addPanels(pgbouncerCommonGraphs.networkStats('patroni', 3001))
.addPanel(keyMetrics.keyServiceMetricsRow('patroni', 'main'), gridPos={ x: 0, y: 4000 })
.addPanel(keyMetrics.keyComponentMetricsRow('patroni', 'main'), gridPos={ x: 0, y: 5000 })
.addPanel(nodeMetrics.nodeMetricsDetailRow('type="patroni", environment="$environment"'), gridPos={ x: 0, y: 6000 })
.addPanel(capacityPlanning.capacityPlanningRow('patroni', 'main'), gridPos={ x: 0, y: 7000 })
+ {
  links+: platformLinks.triage + serviceCatalog.getServiceLinks('patroni') + platformLinks.services,
}

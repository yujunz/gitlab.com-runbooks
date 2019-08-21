local grafana = import 'grafonnet/grafana.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local templates = import 'templates.libsonnet';
local colors = import 'colors.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local layout = import 'layout.libsonnet';
local basic = import 'basic.libsonnet';
local nodeMetrics = import 'node_metrics.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local capacityPlanning = import 'capacity_planning.libsonnet';
local pgbouncerCommonGraphs = import 'pgbouncer_common_graphs.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;

dashboard.new(
  'Overview',
  schemaVersion=16,
  tags=['patroni'],
  timezone='UTC',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addPanel(row.new(title="pgbouncer Connection Pooling"),
  gridPos={
      x: 0,
      y: 0,
      w: 24,
      h: 1,
  }
)
.addPanels(pgbouncerCommonGraphs.connectionPoolingPanels('patroni', 1))
.addPanel(keyMetrics.keyServiceMetricsRow('patroni', 'main'), gridPos={ x: 0, y: 1000, })
.addPanel(keyMetrics.keyComponentMetricsRow('patroni', 'main'), gridPos={ x: 0, y: 2000, })
.addPanel(nodeMetrics.nodeMetricsDetailRow('type="patroni", environment="$environment"'), gridPos={ x: 0, y: 3000, })
.addPanel(capacityPlanning.capacityPlanningRow('patroni', 'main'), gridPos={ x: 0, y: 4000, })
+ {
  links+: platformLinks.triage + serviceCatalog.getServiceLinks('patroni') + platformLinks.services,
}



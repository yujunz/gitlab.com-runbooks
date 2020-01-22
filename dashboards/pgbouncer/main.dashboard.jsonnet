local basic = import 'basic.libsonnet';
local capacityPlanning = import 'capacity_planning.libsonnet';
local colors = import 'colors.libsonnet';
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
local serviceDashboard = import 'service_dashboard.libsonnet';

serviceDashboard.overview('pgbouncer', 'db', stage='main')
.addPanel(
  row.new(title='pgbouncer Workload'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(pgbouncerCommonGraphs.workloadStats('patroni', startRow=2000))
.addPanel(
  row.new(title='pgbouncer Connection Pooling'),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanels(pgbouncerCommonGraphs.connectionPoolingPanels('pgbouncer', 3001))
.addPanel(
  row.new(title='pgbouncer Network'),
  gridPos={
    x: 0,
    y: 4000,
    w: 24,
    h: 1,
  }
)
.addPanels(pgbouncerCommonGraphs.networkStats('pgbouncer', 4001))
.overviewTrailer()

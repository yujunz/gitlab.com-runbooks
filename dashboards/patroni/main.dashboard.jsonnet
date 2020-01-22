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
local processExporter = import 'process_exporter.libsonnet';
local saturationDetail = import 'saturation_detail.libsonnet';
local metricsCatalogDashboards = import 'metrics_catalog_dashboards.libsonnet';

local selector = 'environment="$environment", type="patroni", stage="main"';

basic.dashboard(
  'Overview',
  tags=['patroni'],
)
.addPanels(keyMetrics.headlineMetricsRow('patroni', 'main', startRow=0))
.addPanel(serviceHealth.row('patroni', 'main'), gridPos={ x: 0, y: 500 })
.addPanel(
  row.new(title='pgbouncer Workload', collapse=false),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(pgbouncerCommonGraphs.workloadStats('patroni', 1001))
.addPanel(
  row.new(title='pgbouncer Connection Pooling', collapse=false),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(pgbouncerCommonGraphs.connectionPoolingPanels('patroni', 2001))
.addPanel(
  row.new(title='pgbouncer Network', collapse=false),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanels(pgbouncerCommonGraphs.networkStats('patroni', 3001))
.addPanel(
  row.new(title='patroni process stats'),
  gridPos={
    x: 0,
    y: 4000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  processExporter.namedGroup('patroni', 'patroni', 'patroni', 'main', startRow=4001)
)
.addPanel(keyMetrics.keyServiceMetricsRow('patroni', 'main'), gridPos={ x: 0, y: 5000 })
.addPanel(keyMetrics.keyComponentMetricsRow('patroni', 'main'), gridPos={ x: 0, y: 6000 })
.addPanel(nodeMetrics.nodeMetricsDetailRow(selector), gridPos={ x: 0, y: 7000 })
.addPanel(metricsCatalogDashboards.componentDetailMatrix('patroni', 'service', selector, [
  { title: 'Overall', aggregationLabels: '', legendFormat: 'server' },
  { title: 'per Server', aggregationLabels: 'fqdn', legendFormat: '{{fqdn}}' },
]), gridPos={ x: 0, y: 8000 })
.addPanel(metricsCatalogDashboards.componentDetailMatrix('patroni', 'pgbouncer', selector, [
  { title: 'Overall', aggregationLabels: '', legendFormat: 'pgbouncer' },
  { title: 'per Server', aggregationLabels: 'fqdn', legendFormat: '{{fqdn}}' },
]), gridPos={ x: 0, y: 8100 })
.addPanel(
  saturationDetail.saturationDetailPanels(selector, components=[
    'active_db_connections',
    'cpu',
    'disk_space',
    'memory',
    'open_fds',
    'pgbouncer_async_pool',
    'pgbouncer_single_core',
    'pgbouncer_sync_pool',
    'single_node_cpu',
  ]),
  gridPos={ x: 0, y: 9000, w: 24, h: 1 }
)
.addPanel(capacityPlanning.capacityPlanningRow('patroni', 'main'), gridPos={ x: 0, y: 10000 })
+ {
  links+: platformLinks.triage + serviceCatalog.getServiceLinks('patroni') + platformLinks.services,
}

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

local selector = 'environment="$environment", type="frontend", stage="$stage"';

basic.dashboard(
  'Overview',
  tags=['type:frontend', 'haproxy'],
)
.addTemplate(templates.stage)
.addTemplate(templates.sigma)
.addPanels(keyMetrics.headlineMetricsRow('frontend', '$stage', startRow=0))
.addPanel(serviceHealth.row('frontend', '$stage'), gridPos={ x: 0, y: 500 })
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
    keyMetrics.apdexPanel('frontend', '$stage'),
    keyMetrics.errorRatesPanel('frontend', '$stage'),
    keyMetrics.serviceAvailabilityPanel('frontend', '$stage'),
    keyMetrics.qpsPanel('frontend', '$stage'),
    keyMetrics.saturationPanel('frontend', '$stage'),
  ], startRow=1001)
)
.addPanel(
  row.new(title='HAProxy process'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  processExporter.namedGroup('haproxy', 'haproxy', 'frontend', '$stage', startRow=2001)
)
.addPanel(
  keyMetrics.keyComponentMetricsRow('frontend', '$stage'),
  gridPos={
    x: 0,
    y: 4000,
    w: 24,
    h: 1,
  }
)
.addPanel(
  nodeMetrics.nodeMetricsDetailRow(selector),
  gridPos={
    x: 0,
    y: 5000,
    w: 24,
    h: 1,
  }
)
.addPanel(
  saturationDetail.saturationDetailPanels(selector, components=[
    'cpu',
    'disk_space',
    'memory',
    'open_fds',
    'single_node_cpu',
  ]),
  gridPos={ x: 0, y: 6000, w: 24, h: 1 }
)
.addPanel(capacityPlanning.capacityPlanningRow('frontend', '$stage'), gridPos={ x: 0, y: 7000 })
+ {
  links+: platformLinks.triage + serviceCatalog.getServiceLinks('frontend') + platformLinks.services,
}

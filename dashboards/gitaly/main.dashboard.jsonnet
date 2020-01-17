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
local saturationDetail = import 'saturation_detail.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local serviceHealth = import 'service_health.libsonnet';
local metricsCatalogDashboards = import 'metrics_catalog_dashboards.libsonnet';
local gitalyCommon = import 'gitaly/gitaly_common.libsonnet';

local selector = 'environment="$environment", type="gitaly", stage="$stage"';

basic.dashboard(
  'Overview',
  tags=['type:gitaly'],
)
.addTemplate(templates.stage)
.addTemplate(templates.sigma)
.addPanels(keyMetrics.headlineMetricsRow('gitaly', '$stage', startRow=0))
.addPanel(serviceHealth.row('gitaly', '$stage'), gridPos={ x: 0, y: 1000 })
.addPanel(
  row.new(title='Node Performance'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    gitalyCommon.perNodeApdex(selector),
    gitalyCommon.inflightGitalyCommandsPerNode(selector),
    gitalyCommon.readThroughput(selector),
    gitalyCommon.writeThroughput(selector),
  ], startRow=2001)
)
.addPanel(
  row.new(title='Gitaly Safety Mechanisms'),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    gitalyCommon.gitalySpawnTimeoutsPerNode(selector),
    gitalyCommon.ratelimitLockPercentage(selector),
  ], startRow=3001)
)
.addPanel(keyMetrics.keyServiceMetricsRow('gitaly', '$stage'), gridPos={ x: 0, y: 4000 })
.addPanel(keyMetrics.keyComponentMetricsRow('gitaly', '$stage'), gridPos={ x: 0, y: 5000 })
.addPanel(nodeMetrics.nodeMetricsDetailRow(selector), gridPos={ x: 0, y: 6000 })
.addPanel(
  saturationDetail.saturationDetailPanels(selector, components=[
    'cgroup_memory',
    'cpu',
    'disk_space',
    'disk_sustained_read_iops',
    'disk_sustained_read_throughput',
    'disk_sustained_write_iops',
    'disk_sustained_write_throughput',
    'memory',
    'open_fds',
    'single_node_cpu',
    'go_memory',
  ]),
  gridPos={ x: 0, y: 6000, w: 24, h: 1 }
)
.addPanel(
  metricsCatalogDashboards.componentDetailMatrix(
    'gitaly',
    'goserver',
    selector,
    [
      { title: 'Overall', aggregationLabels: '', legendFormat: 'goserver' },
      { title: 'per Node', aggregationLabels: 'fqdn', legendFormat: '{{ fqdn }}' },
    ],
  ), gridPos={ x: 0, y: 7000 }
)
.addPanel(
  metricsCatalogDashboards.componentDetailMatrix(
    'gitaly',
    'gitalyruby',
    selector,
    [
      { title: 'Overall', aggregationLabels: '', legendFormat: 'gitalyruby' },
      { title: 'per Node', aggregationLabels: 'fqdn', legendFormat: '{{ fqdn }}' },
    ],
  ), gridPos={ x: 0, y: 7100 }
)
.addPanel(capacityPlanning.capacityPlanningRow('gitaly', '$stage'), gridPos={ x: 0, y: 8000 })
+ {
  links+: platformLinks.triage + serviceCatalog.getServiceLinks('gitaly') + platformLinks.services +
          [platformLinks.dynamicLinks('Gitaly Detail', 'type:gitaly')],
}

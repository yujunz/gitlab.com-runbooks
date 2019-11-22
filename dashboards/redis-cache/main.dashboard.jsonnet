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
local redisCommon = import 'redis_common_graphs.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local serviceHealth = import 'service_health.libsonnet';
local saturationDetail = import 'saturation_detail.libsonnet';

dashboard.new(
  'Overview',
  schemaVersion=16,
  tags=['redis-cache', 'overview'],
  timezone='utc',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addPanels(keyMetrics.headlineMetricsRow('redis-cache', '$stage', startRow=0))
.addPanel(serviceHealth.row('redis-cache', '$stage'), gridPos={ x: 0, y: 500 })
.addPanel(
  row.new(title='Clients'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(redisCommon.clientPanels(serviceType='redis-cache', startRow=1001))
.addPanel(
  row.new(title='Workload'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(redisCommon.workload(serviceType='redis-cache', startRow=2001))
.addPanel(
  row.new(title='Redis Data'),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanels(redisCommon.data(serviceType='redis-cache', startRow=3001))
.addPanel(
  row.new(title='Replication'),
  gridPos={
    x: 0,
    y: 4000,
    w: 24,
    h: 1,
  }
)
.addPanels(redisCommon.replication(serviceType='redis-cache', startRow=4001))

.addPanel(keyMetrics.keyServiceMetricsRow('redis-cache', 'main'), gridPos={ x: 0, y: 5000 })
.addPanel(keyMetrics.keyComponentMetricsRow('redis-cache', 'main'), gridPos={ x: 0, y: 6000 })
.addPanel(nodeMetrics.nodeMetricsDetailRow('type="redis-cache", environment="$environment", fqdn=~"redis-cache-\\d\\d.*"'), gridPos={ x: 0, y: 7000 })
.addPanel(
  saturationDetail.saturationDetailPanels('redis-cache', 'main', components=[
    'cpu',
    'disk_space',
    'memory',
    'open_fds',
    'redis_clients',
    'redis_memory',
    'single_node_cpu',
    'single_threaded_cpu',
  ]),
  gridPos={ x: 0, y: 8000, w: 24, h: 1 }
)
.addPanel(capacityPlanning.capacityPlanningRow('redis-cache', 'main'), gridPos={ x: 0, y: 9000 })
+ {
  links+: platformLinks.triage + serviceCatalog.getServiceLinks('redis-cache') + platformLinks.services,
}

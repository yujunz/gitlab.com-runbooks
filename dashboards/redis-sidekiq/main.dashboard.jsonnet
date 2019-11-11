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

dashboard.new(
  'Overview',
  schemaVersion=16,
  tags=['redis', 'overview'],
  timezone='utc',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addPanel(serviceHealth.row('redis-sidekiq', '$stage'), gridPos={ x: 0, y: 0 })
.addPanel(
row.new(title='Clients'),
  gridPos={
      x: 0,
      y: 1000,
      w: 24,
      h: 1,
  }
)
.addPanels(redisCommon.clientPanels(serviceType='redis-sidekiq', startRow=1001))
.addPanel(
row.new(title='Workload'),
  gridPos={
      x: 0,
      y: 2000,
      w: 24,
      h: 1,
  }
)
.addPanels(redisCommon.workload(serviceType='redis-sidekiq', startRow=2001))
.addPanel(
row.new(title='Redis Data'),
  gridPos={
      x: 0,
      y: 3000,
      w: 24,
      h: 1,
  }
)
.addPanels(redisCommon.data(serviceType='redis-sidekiq', startRow=3001))
.addPanel(
row.new(title='Replication'),
  gridPos={
      x: 0,
      y: 4000,
      w: 24,
      h: 1,
  }
)
.addPanels(redisCommon.replication(serviceType='redis-sidekiq', startRow=4001))

.addPanel(keyMetrics.keyServiceMetricsRow('redis-sidekiq', 'main'), gridPos={ x: 0, y: 5000 })
.addPanel(keyMetrics.keyComponentMetricsRow('redis-sidekiq', 'main'), gridPos={ x: 0, y: 6000 })
.addPanel(nodeMetrics.nodeMetricsDetailRow('type="redis-sidekiq", environment="$environment"'), gridPos={ x: 0, y: 7000 })
.addPanel(capacityPlanning.capacityPlanningRow('redis-sidekiq', 'main'), gridPos={ x: 0, y: 8000 })
+ {
  links+: platformLinks.triage + serviceCatalog.getServiceLinks('redis-sidekiq') + platformLinks.services,
}

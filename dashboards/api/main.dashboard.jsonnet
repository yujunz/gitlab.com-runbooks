local grafana = import 'grafonnet/grafana.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local templates = import 'templates.libsonnet';
local colors = import 'colors.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local capacityPlanning = import 'capacity_planning.libsonnet';
local layout = import 'layout.libsonnet';
local basic = import 'basic.libsonnet';
local workhorseCommon = import 'workhorse_common_graphs.libsonnet';
local railsCommon = import 'rails_common_graphs.libsonnet';
local nodeMetrics = import 'node_metrics.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;

dashboard.new(
  'Overview',
  schemaVersion=16,
  tags=['overview'],
  timezone='UTC',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addTemplate(templates.stage)
.addPanel(row.new(title="Workhorse"),
  gridPos={
      x: 0,
      y: 0,
      w: 24,
      h: 1,
  }
)
.addPanels(workhorseCommon.workhorsePanels(serviceType="api", serviceStage="$stage", startRow=1))

.addPanel(row.new(title="Rails"),
  gridPos={
      x: 0,
      y: 1000,
      w: 24,
      h: 1,
  }
)
.addPanels(railsCommon.railsPanels(serviceType="api", serviceStage="$stage", startRow=1001))

.addPanel(keyMetrics.keyServiceMetricsRow('api', '$stage'), gridPos={ x: 0, y: 4000, })
.addPanel(keyMetrics.keyComponentMetricsRow('api', '$stage'), gridPos={ x: 0, y: 5000, })
.addPanel(nodeMetrics.nodeMetricsDetailRow('type="api", environment="$environment", stage="$stage"'), gridPos={ x: 0, y: 6000, })
.addPanel(capacityPlanning.capacityPlanningRow('api', '$stage'), gridPos={ x: 0, y: 7000, })
+ {
  links+: platformLinks.triage + serviceCatalog.getServiceLinks('api') + platformLinks.services,
}



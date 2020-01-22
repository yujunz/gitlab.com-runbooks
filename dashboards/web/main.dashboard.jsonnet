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
local railsCommon = import 'rails_common_graphs.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local templates = import 'templates.libsonnet';
local unicornCommon = import 'unicorn_common_graphs.libsonnet';
local workhorseCommon = import 'workhorse_common_graphs.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local serviceHealth = import 'service_health.libsonnet';
local saturationDetail = import 'saturation_detail.libsonnet';
local serviceDashboard = import 'service_dashboard.libsonnet';

local selector = 'environment="$environment", type="web", stage="$stage"';

serviceDashboard.overview('web', 'sv')
.addPanel(
  row.new(title='Workhorse'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(workhorseCommon.workhorsePanels(serviceType='web', serviceStage='$stage', startRow=1001))
.addPanel(
  row.new(title='Unicorn'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(unicornCommon.unicornPanels(serviceType='web', serviceStage='$stage', startRow=2001))
.addPanel(
  row.new(title='Rails'),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanels(railsCommon.railsPanels(serviceType='web', serviceStage='$stage', startRow=3001))
.addPanel(workhorseCommon.componentDetailsRow('web', selector), gridPos={ x: 0, y: 5000 })
.addPanel(unicornCommon.componentDetailsRow('web', selector), gridPos={ x: 0, y: 5100 })
.overviewTrailer()

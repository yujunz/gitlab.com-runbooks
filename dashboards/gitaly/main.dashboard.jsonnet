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
local serviceDashboard = import 'service_dashboard.libsonnet';

local selector = 'environment="$environment", type="gitaly", stage="$stage"';

serviceDashboard.overview('gitaly', 'stor')
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
.overviewTrailer()

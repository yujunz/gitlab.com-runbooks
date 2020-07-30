local basic = import 'grafana/basic.libsonnet';
local capacityPlanning = import 'capacity_planning.libsonnet';
local colors = import 'grafana/colors.libsonnet';
local commonAnnotations = import 'grafana/common_annotations.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local nodeMetrics = import 'node_metrics.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local saturationDetail = import 'saturation_detail.libsonnet';
local seriesOverrides = import 'grafana/series_overrides.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local serviceHealth = import 'service_health.libsonnet';
local metricsCatalogDashboards = import 'metrics_catalog_dashboards.libsonnet';
local gitalyCommon = import 'gitaly/gitaly_common.libsonnet';
local serviceDashboard = import 'service_dashboard.libsonnet';
local processExporter = import 'process_exporter.libsonnet';

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
.addPanel(
  row.new(title='git process activity'),
  gridPos={
    x: 0,
    y: 4000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  processExporter.namedGroup(
    'git processes',
    {
      groupname: { re: 'git.*' },
      environment: '$environment',
      type: 'gitaly',
      stage: '$stage',
    },
    aggregationLabels=['groupname'],
    startRow=4001
  )
)
.overviewTrailer()

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
local metricsCatalogDashboards = import 'metrics_catalog_dashboards.libsonnet';

local selector = 'environment="$environment", type="registry", stage="$stage"';

local registryServerComponentDetailRow() =
  local aggregationSets = [
    { title: 'Overall', aggregationLabels: '', legendFormat: 'server' },
    { title: 'per Handler', aggregationLabels: 'handler', legendFormat: '{{ handler }}' },
  ];
  metricsCatalogDashboards.componentDetailMatrix('registry', 'server', selector, aggregationSets);

local registryStorageComponentDetailRow() =
  local aggregationSets = [
    { title: 'Overall', aggregationLabels: '', legendFormat: 'server' },
    { title: 'per Action', aggregationLabels: 'action', legendFormat: '{{ action }}' },
  ];
  metricsCatalogDashboards.componentDetailMatrix('registry', 'storage', selector, aggregationSets);


basic.dashboard(
  'Overview',
  tags=['registry', 'overview'],
)
.addTemplate(templates.stage)
.addPanels(keyMetrics.headlineMetricsRow('registry', '$stage', startRow=0))
.addPanel(serviceHealth.row('registry', '$stage'), gridPos={ x: 0, y: 500 })
.addPanel(keyMetrics.keyServiceMetricsRow('registry', '$stage'), gridPos={ x: 0, y: 4000 })
.addPanel(registryServerComponentDetailRow(), gridPos={ x: 0, y: 5000 })
.addPanel(registryStorageComponentDetailRow(), gridPos={ x: 0, y: 5100 })
.addPanel(saturationDetail.saturationDetailPanels(selector, components=[
            'cpu',
            'disk_space',
            'memory',
            'open_fds',
            'single_node_cpu',
            'go_memory',
          ]),
          gridPos={ x: 0, y: 7000, w: 24, h: 1 })
.addPanel(capacityPlanning.capacityPlanningRow('registry', '$stage'), gridPos={ x: 0, y: 8000 })
+ {
  links+: platformLinks.triage + serviceCatalog.getServiceLinks('registry') + platformLinks.services,
}

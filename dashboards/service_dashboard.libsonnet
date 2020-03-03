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
local saturationDetail = import 'saturation_detail.libsonnet';
local metricsCatalog = import 'metrics-catalog.libsonnet';
local metricsCatalogDashboards = import 'metrics_catalog_dashboards.libsonnet';
local selectors = import './lib/selectors.libsonnet';

local listComponentThresholds(service) =
  std.prune([
    if std.objectHas(service.components[componentName], 'apdex') then
      ' * %s: %s' % [componentName, service.components[componentName].apdex.describe()]
    else
      null
    for componentName in std.objectFields(service.components)
  ]);

local getApdexDescription(metricsCatalogServiceInfo) =
  std.join('  \n', [
    '_Apdex is a measure of requests that complete within a tolerable period of time for the service. Higher is better._\n',
    '### Component Thresholds',
    '_Satisfactory/Tolerable_',
  ] + listComponentThresholds(metricsCatalogServiceInfo));

local headlineMetricsRow(serviceType, serviceStage, startRow, metricsCatalogServiceInfo) =
  local hasApdex = metricsCatalogServiceInfo.hasApdex();
  local hasErrorRate = metricsCatalogServiceInfo.hasErrorRate();
  local hasRequestRate = metricsCatalogServiceInfo.hasRequestRate();

  local cells = std.prune([
    if hasApdex then keyMetrics.apdexPanel(serviceType, serviceStage, compact=true, description=getApdexDescription(metricsCatalogServiceInfo)) else null,
    if hasErrorRate then keyMetrics.errorRatesPanel(serviceType, serviceStage, compact=true) else null,
    if hasRequestRate then keyMetrics.qpsPanel(serviceType, serviceStage, compact=true) else null,
    keyMetrics.saturationPanel(serviceType, serviceStage, compact=true),
  ]);

  layout.grid([
    row.new(title='🌡️ Service Level Indicators (𝙎𝙇𝙄𝙨)', collapse=false),
  ], cols=1, rowHeight=1, startRow=startRow)
  +
  layout.grid(cells, cols=std.length(cells), rowHeight=5, startRow=startRow + 1);

local overviewDashboard(type, tier, stage) =
  local selectorHash = {
    environment: '$environment',
    type: type,
    stage: stage,
  };
  local selector = selectors.serializeHash(selectorHash);
  local catalogServiceInfo = serviceCatalog.lookupService(type);
  local metricsCatalogServiceInfo = metricsCatalog.getService(type);

  local dashboard =
    basic.dashboard(
      'Overview',
      tags=['type:' + type, 'tier:' + tier, type, 'service overview'],
    )
    .addPanels(headlineMetricsRow(type, stage, 0, metricsCatalogServiceInfo))
    .addPanel(serviceHealth.row(type, stage), gridPos={ x: 0, y: 10 })
    .addPanels(
      metricsCatalogDashboards.componentOverviewMatrix(
        type,
        stage,
        startRow=20
      )
    )
    .addPanels(
      metricsCatalogDashboards.autoDetailRows(type, selectorHash, startRow=100)
    )
    .addPanel(
      nodeMetrics.nodeMetricsDetailRow(selector),
      gridPos={
        x: 0,
        y: 300,
        w: 24,
        h: 1,
      }
    )
    .addPanel(
      saturationDetail.saturationDetailPanels(selector, components=metricsCatalogServiceInfo.saturationTypes),
      gridPos={ x: 0, y: 400, w: 24, h: 1 }
    );

  // Optionally add the stage variable
  local dashboardWithStage = if stage == '$stage' then dashboard.addTemplate(templates.stage) else dashboard;

  dashboardWithStage.addTemplate(templates.sigma);

{
  overview(type, tier, stage='$stage')::
    overviewDashboard(type, tier, stage) {
      _serviceType: type,
      _serviceTier: tier,
      _stage: stage,
      overviewTrailer()::
        local s = self;
        local p =
          s.addPanel(capacityPlanning.capacityPlanningRow(s._serviceType, s._stage), gridPos={ x: 0, y: 100000 })
          + {
            links+: platformLinks.triage + serviceCatalog.getServiceLinks(s._serviceType) + platformLinks.services + [platformLinks.dynamicLinks(s._serviceType + ' Detail', 'type:' + s._serviceType)],
          };

        p.trailer(),
    },

}

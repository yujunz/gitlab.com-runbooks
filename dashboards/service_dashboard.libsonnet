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
local systemDiagramPanel = import 'system_diagram_panel.libsonnet';
local kubeEmbeddedDashboards = import 'kubernetes_embedded_dashboards.libsonnet';
local statusDescription = import 'status_description.libsonnet';

local defaultEnvironmentSelector = { environment: '$environment' };

local listComponentThresholds(service) =
  std.prune([
    if service.components[componentName].hasApdex() then
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

local headlineMetricsRow(
  serviceType,
  serviceStage,
  startRow,
  metricsCatalogServiceInfo,
  environmentSelectorHash,
  saturationEnvironmentSelectorHash,
  showSaturationCell,
      ) =
  local hasApdex = metricsCatalogServiceInfo.hasApdex();
  local hasErrorRate = metricsCatalogServiceInfo.hasErrorRate();
  local hasRequestRate = metricsCatalogServiceInfo.hasRequestRate();
  local serviceSelector = environmentSelectorHash { type: serviceType, stage: serviceStage };

  local columns =
    (
      if hasApdex then
        [[
          keyMetrics.apdexPanel(serviceType, serviceStage, compact=true, environmentSelectorHash=environmentSelectorHash, description=getApdexDescription(metricsCatalogServiceInfo)),
          statusDescription.serviceApdexStatusDescriptionPanel(serviceSelector),
        ]]
      else
        []
    )
    +
    (
      if hasErrorRate then
        [[
          keyMetrics.errorRatesPanel(serviceType, serviceStage, compact=true, environmentSelectorHash=environmentSelectorHash),
          statusDescription.serviceErrorStatusDescriptionPanel(serviceSelector),
        ]]
      else
        []
    )
    +
    (
      if hasRequestRate then
        [[
          keyMetrics.qpsPanel(serviceType, serviceStage, compact=true, environmentSelectorHash=environmentSelectorHash),
        ]]
      else
        []
    )
    +
    (
      if showSaturationCell then
        [[
          keyMetrics.saturationPanel(serviceType, serviceStage, compact=true, environmentSelectorHash=saturationEnvironmentSelectorHash),
        ]]
      else
        []
    );

  layout.grid([row.new(title='🌡️ Service Level Indicators (𝙎𝙇𝙄𝙨)', collapse=false)], cols=1, rowHeight=1, startRow=startRow)
  +
  layout.splitColumnGrid(columns, [5, 1], startRow=startRow + 1);

local overviewDashboard(
  type,
  tier,
  stage,
  environmentSelectorHash,
  saturationEnvironmentSelectorHash
      ) =
  local selectorHash = environmentSelectorHash { type: type, stage: stage };
  local selector = selectors.serializeHash(selectorHash);
  local catalogServiceInfo = serviceCatalog.lookupService(type);
  local metricsCatalogServiceInfo = metricsCatalog.getService(type);
  local saturationComponents = metricsCatalogServiceInfo.applicableSaturationTypes();

  local dashboard =
    basic.dashboard(
      'Overview',
      tags=['type:' + type, 'tier:' + tier, type, 'service overview'],
      includeEnvironmentTemplate=environmentSelectorHash == defaultEnvironmentSelector,
    )
    .addPanels(
      headlineMetricsRow(
        type,
        stage,
        startRow=0,
        metricsCatalogServiceInfo=metricsCatalogServiceInfo,
        environmentSelectorHash=environmentSelectorHash,
        saturationEnvironmentSelectorHash=saturationEnvironmentSelectorHash,
        showSaturationCell=std.length(saturationComponents) > 0
      )
    )
    .addPanels([
      serviceHealth.row(type, stage, environmentSelectorHash) { gridPos: { x: 0, y: 10 } },
    ])
    .addPanels(
      metricsCatalogDashboards.componentOverviewMatrix(
        type,
        stage,
        startRow=20,
        environmentSelectorHash=environmentSelectorHash,
      )
    )
    .addPanels(
      metricsCatalogDashboards.autoDetailRows(type, selectorHash, startRow=100)
    )
    .addPanels(
      if metricsCatalogServiceInfo.getProvisioning().vms == true then
        [
          nodeMetrics.nodeMetricsDetailRow(selector) {
            gridPos: {
              x: 0,
              y: 300,
              w: 24,
              h: 1,
            },
          },
        ] else []
    )
    .addPanels(
      if metricsCatalogServiceInfo.getProvisioning().kubernetes == true then
        // TODO: fix nasty regexp: requires https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10249
        local kubeSelectorHash = { environment: '$environment', pod_name: { re: 'gitlab-%s.*' % [type] } };
        [
          row.new(title='☸️ Kubernetes Overview', collapse=true)
          .addPanels(kubeEmbeddedDashboards.kubernetesOverview(kubeSelectorHash, startRow=1)) +
          { gridPos: { x: 0, y: 400, w: 24, h: 1 } },
        ]
      else [],
    )
    .addPanels(
      if std.length(saturationComponents) > 0 then
        [
          // saturationSelector is env + type + stage
          local saturationSelector = saturationEnvironmentSelectorHash { type: type, stage: stage };
          saturationDetail.saturationDetailPanels(saturationSelector, components=saturationComponents)
          { gridPos: { x: 0, y: 500, w: 24, h: 1 } },
        ]
      else []
    );

  // Optionally add the stage variable
  local dashboardWithStage = if stage == '$stage' then dashboard.addTemplate(templates.stage) else dashboard;

  dashboardWithStage.addTemplate(templates.sigma)
  {
    overviewTrailer()::
      local s = self;
      self
      .addPanels(
        if std.length(saturationComponents) > 0 then
          [
            capacityPlanning.capacityPlanningRow(type, stage) { gridPos: { x: 0, y: 100000 } },
          ] else []
      )
      .addPanel(
        systemDiagramPanel.systemDiagramRowForService(type),
        gridPos={ x: 0, y: 100010 }
      )
      .trailer()
      + {
        links+:
          platformLinks.triage +
          serviceCatalog.getServiceLinks(type) +
          platformLinks.services +
          [
            platformLinks.dynamicLinks(type + ' Detail', 'type:' + type),
          ],
      },
  };


{
  overview(
    type,
    tier,
    stage='$stage',
    environmentSelectorHash=defaultEnvironmentSelector,
    saturationEnvironmentSelectorHash=defaultEnvironmentSelector
  )::
    overviewDashboard(
      type,
      tier,
      stage,
      environmentSelectorHash=environmentSelectorHash,
      saturationEnvironmentSelectorHash=saturationEnvironmentSelectorHash
    ),
}

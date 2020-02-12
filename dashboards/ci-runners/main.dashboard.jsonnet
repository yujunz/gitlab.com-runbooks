local basic = import 'basic.libsonnet';
local capacityPlanning = import 'capacity_planning.libsonnet';
local colors = import 'colors.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local layout = import 'layout.libsonnet';
local nodeMetrics = import 'node_metrics.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local serviceHealth = import 'service_health.libsonnet';
local saturationDetail = import 'saturation_detail.libsonnet';
local metricsCatalogDashboards = import 'metrics_catalog_dashboards.libsonnet';
local selectors = import 'lib/selectors.libsonnet';

local selectorHash = {
  environment: '$environment',
  type: 'ci-runners',
  stage: '$stage',
};

local selector = selectors.serializeHash(selectorHash);

basic.dashboard(
  'Overview',
  tags=['ci-runners', 'overview'],
)
.addTemplate(templates.stage)
.addPanels(keyMetrics.headlineMetricsRow('ci-runners', '$stage', startRow=0))
.addPanel(serviceHealth.row('ci-runners', '$stage'), gridPos={ x: 0, y: 500 })
.addPanel(keyMetrics.keyServiceMetricsRow('ci-runners', '$stage'), gridPos={ x: 0, y: 4000 })
.addPanel(
  metricsCatalogDashboards.componentDetailMatrix(
    'ci-runners',
    'polling',
    selectorHash,
    [
      { title: 'Overall', aggregationLabels: '', legendFormat: 'polling' },
      { title: 'By Status', aggregationLabels: 'status', legendFormat: '{{ status }}' },
    ],
  ), gridPos={ x: 0, y: 5000 }
)
.addPanel(
  metricsCatalogDashboards.componentDetailMatrix(
    'ci-runners',
    'shared_runner_queues',
    selectorHash,
    [
      { title: 'Overall', aggregationLabels: '', legendFormat: 'shared_runner_queues' },
    ],
  ), gridPos={ x: 0, y: 5100 }
)
.addPanel(saturationDetail.saturationDetailPanels(selector, components=[
            'private_runners',
            'shared_runners',
            'shared_runners_gitlab',
          ]),
          gridPos={ x: 0, y: 7000, w: 24, h: 1 })
.addPanel(capacityPlanning.capacityPlanningRow('ci-runners', '$stage'), gridPos={ x: 0, y: 8000 })
+ {
  links+: platformLinks.triage + serviceCatalog.getServiceLinks('ci-runners') + platformLinks.services,
}

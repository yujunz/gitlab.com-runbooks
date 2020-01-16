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

local selector = 'environment="$environment", type="monitoring", stage="$stage"';

dashboard.new(
  'Overview',
  schemaVersion=16,
  tags=['overview'],
  timezone='utc',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addTemplate(templates.stage)
.addPanels(keyMetrics.headlineMetricsRow('monitoring', '$stage', startRow=0))
.addPanel(serviceHealth.row('monitoring', '$stage'), gridPos={ x: 0, y: 500 })
.addPanel(keyMetrics.keyServiceMetricsRow('monitoring', '$stage'), gridPos={ x: 0, y: 4000 })
.addPanel(
  metricsCatalogDashboards.componentDetailMatrix(
    'monitoring',
    'prometheus',
    selector,
    [
      { title: 'Overall', aggregationLabels: '', legendFormat: 'prometheus' },
      { title: 'per Node', aggregationLabels: 'fqdn', legendFormat: '{{ fqdn }}' },
    ],
    minLatency=0.001,
  ), gridPos={ x: 0, y: 5000 }
)
.addPanel(
  metricsCatalogDashboards.componentDetailMatrix(
    'monitoring',
    'thanos_query',
    selector,
    [
      { title: 'Overall', aggregationLabels: '', legendFormat: 'thanos_query' },
      { title: 'per Node', aggregationLabels: 'fqdn', legendFormat: '{{ fqdn }}' },
    ],
    minLatency=0.001,
  ), gridPos={ x: 0, y: 5100 }
)
.addPanel(
  metricsCatalogDashboards.componentDetailMatrix(
    'monitoring',
    'thanos_store',
    selector,
    [
      { title: 'Overall', aggregationLabels: '', legendFormat: 'thanos_store' },
      { title: 'per Node', aggregationLabels: 'fqdn', legendFormat: '{{ fqdn }}' },
    ],
    minLatency=0.001,
  ), gridPos={ x: 0, y: 5200 }
)
.addPanel(
  metricsCatalogDashboards.componentDetailMatrix(
    'monitoring',
    'grafana',
    selector,
    [
      { title: 'Overall', aggregationLabels: '', legendFormat: 'grafana' },
      { title: 'per Node', aggregationLabels: 'fqdn', legendFormat: '{{ fqdn }}' },
    ],
  ), gridPos={ x: 0, y: 5300 }
)
.addPanel(saturationDetail.saturationDetailPanels(selector, components=[
            'cpu',
            'disk_space',
            'memory',
            'open_fds',
            'single_node_cpu',
            'go_memory',
          ]),
          gridPos={ x: 0, y: 7000, w: 24, h: 1 })
.addPanel(capacityPlanning.capacityPlanningRow('monitoring', '$stage'), gridPos={ x: 0, y: 8000 })
+ {
  links+: platformLinks.triage + serviceCatalog.getServiceLinks('monitoring') + platformLinks.services,
}
